import Darwin
import Foundation

public enum IPCError: LocalizedError {
    case notFound, disconnected, timeout, invalidResponse
    case rejected(String)
    public var errorDescription: String? {
        switch self {
        case .notFound: return "Discord not found: open the Discord app on this Mac."
        case .disconnected: return "Discord disconnected. Retrying automatically."
        case .timeout: return "Discord is not responding. Retrying automatically."
        case .invalidResponse: return "Invalid response from Discord."
        case .rejected(let reason): return reason
        }
    }
}

/// Use on a single background queue. All I/O is bounded; a blocked Discord never freezes the UI.
public final class DiscordIPC: DiscordTransport {
    private var fd: Int32 = -1
    private var clientID = ""
    public private(set) var connected = false
    public init() {}
    deinit { disconnect() }
    public func disconnect() {
        if fd >= 0 { Darwin.close(fd) }
        fd = -1
        connected = false
        clientID = ""
    }
    public static func validClientID(_ id: String) -> Bool {
        (17...20).contains(id.count) && id.utf8.allSatisfy { (48...57).contains($0) }
    }
    public static var socketPaths: [String] {
        let env = ProcessInfo.processInfo.environment
        var roots = ["XDG_RUNTIME_DIR", "TMPDIR", "TMP", "TEMP"].compactMap { env[$0] }
        roots += [NSTemporaryDirectory(), "/tmp"]
        var seen = Set<String>()
        return roots.filter { seen.insert(URL(fileURLWithPath: $0).standardizedFileURL.path).inserted }
            .flatMap { root in
                (0..<10).map { URL(fileURLWithPath: root).appendingPathComponent("discord-ipc-\($0)").path }
            }
    }
    public func connect(clientID: String) throws {
        try connect(clientID: clientID, paths: nil)
    }
    public func connect(clientID: String, paths: [String]?) throws {
        guard Self.validClientID(clientID) else { throw IPCError.rejected("Invalid Application ID") }
        if connected && self.clientID == clientID { return }
        disconnect()
        for path in paths ?? Self.socketPaths {
            var statInfo = stat()
            guard lstat(path, &statInfo) == 0, statInfo.st_uid == getuid(),
                (statInfo.st_mode & S_IFMT) == S_IFSOCK
            else { continue }
            var address = sockaddr_un()
            let bytes = Array(path.utf8) + [0]
            guard bytes.count <= MemoryLayout.size(ofValue: address.sun_path) else { continue }
            address.sun_family = sa_family_t(AF_UNIX)
            address.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
            withUnsafeMutableBytes(of: &address.sun_path) { $0.copyBytes(from: bytes) }
            let candidate = socket(AF_UNIX, SOCK_STREAM, 0)
            guard candidate >= 0 else { continue }
            configure(candidate)
            let status = withUnsafePointer(to: &address) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    Darwin.connect(candidate, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
                }
            }
            guard status == 0 || errno == EINPROGRESS else {
                Darwin.close(candidate)
                continue
            }
            fd = candidate
            do {
                try wait(POLLOUT, deadline: Date().addingTimeInterval(1))
                var error: Int32 = 0
                var length = socklen_t(MemoryLayout<Int32>.size)
                guard getsockopt(fd, SOL_SOCKET, SO_ERROR, &error, &length) == 0, error == 0 else {
                    throw IPCError.disconnected
                }
                try send(
                    opcode: 0, data: JSONSerialization.data(withJSONObject: ["v": 1, "client_id": clientID]))
                let ready = try receiveJSON(until: Date().addingTimeInterval(3)) {
                    $0["evt"] as? String == "READY"
                }
                guard ready["evt"] as? String == "READY" else { throw IPCError.invalidResponse }
                connected = true
                self.clientID = clientID
                return
            } catch {
                disconnect()
                throw error
            }
        }
        throw IPCError.notFound
    }
    @discardableResult public func setActivity(_ activity: [String: Any]?) throws -> Date {
        try setActivity(activity, pid: getpid())
    }
    @discardableResult public func setActivity(_ activity: [String: Any]?, pid: Int32) throws -> Date {
        guard connected else { throw IPCError.disconnected }
        let nonce = UUID().uuidString
        do {
            let command: [String: Any] = [
                "cmd": "SET_ACTIVITY", "args": ["pid": pid, "activity": activity as Any? ?? NSNull()],
                "nonce": nonce,
            ]
            try send(opcode: 1, data: JSONSerialization.data(withJSONObject: command))
            let reply = try receiveJSON(until: Date().addingTimeInterval(3)) {
                $0["nonce"] as? String == nonce
            }
            guard reply["cmd"] as? String == "SET_ACTIVITY" else { throw IPCError.invalidResponse }
            return Date()
        } catch {
            disconnect()
            throw error
        }
    }
    private func configure(_ descriptor: Int32) {
        _ = fcntl(descriptor, F_SETFL, fcntl(descriptor, F_GETFL) | O_NONBLOCK)
        _ = fcntl(descriptor, F_SETFD, FD_CLOEXEC)
        var yes: Int32 = 1
        _ = setsockopt(descriptor, SOL_SOCKET, SO_NOSIGPIPE, &yes, socklen_t(MemoryLayout<Int32>.size))
    }
    private func wait(_ events: Int32, deadline: Date) throws {
        while true {
            let ms = Int32(max(0, min(3000, deadline.timeIntervalSinceNow * 1000)))
            guard ms > 0 else { throw IPCError.timeout }
            var item = pollfd(fd: fd, events: Int16(events), revents: 0)
            let result = poll(&item, 1, ms)
            if result < 0 && errno == EINTR { continue }
            guard result >= 0 else { throw IPCError.disconnected }
            guard result > 0 else { throw IPCError.timeout }
            if item.revents & Int16(events) != 0 { return }
            throw IPCError.disconnected
        }
    }
    func send(opcode: UInt32, data: Data) throws {
        guard data.count <= 1_048_576 else { throw IPCError.invalidResponse }
        var op = opcode.littleEndian
        var size = UInt32(data.count).littleEndian
        var frame = Data(bytes: &op, count: 4)
        frame.append(Data(bytes: &size, count: 4))
        frame.append(data)
        let deadline = Date().addingTimeInterval(3)
        try frame.withUnsafeBytes { bytes in
            var offset = 0
            while offset < bytes.count {
                try wait(POLLOUT, deadline: deadline)
                let n = Darwin.write(fd, bytes.baseAddress!.advanced(by: offset), bytes.count - offset)
                if n < 0 && (errno == EAGAIN || errno == EINTR) { continue }
                guard n > 0 else { throw IPCError.disconnected }
                offset += n
            }
        }
    }
    func readExactly(_ count: Int, deadline: Date) throws -> Data {
        var data = Data(count: count)
        try data.withUnsafeMutableBytes { bytes in
            var offset = 0
            while offset < count {
                try wait(POLLIN, deadline: deadline)
                let n = Darwin.read(fd, bytes.baseAddress!.advanced(by: offset), count - offset)
                if n < 0 && (errno == EAGAIN || errno == EINTR) { continue }
                guard n > 0 else { throw IPCError.disconnected }
                offset += n
            }
        }
        return data
    }
    private func receiveJSON(until deadline: Date, matching: ([String: Any]) -> Bool) throws -> [String: Any]
    {
        while Date() < deadline {
            let header = try readExactly(8, deadline: deadline)
            let opcode = header.withUnsafeBytes { UInt32(littleEndian: $0.loadUnaligned(as: UInt32.self)) }
            let length = header.withUnsafeBytes {
                UInt32(littleEndian: $0.loadUnaligned(fromByteOffset: 4, as: UInt32.self))
            }
            guard length <= 1_048_576 else { throw IPCError.invalidResponse }
            let body = try readExactly(Int(length), deadline: deadline)
            if opcode == 3 {
                try send(opcode: 4, data: body)
                continue
            }
            if opcode == 2 { throw IPCError.disconnected }
            guard opcode == 1, let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            else { throw IPCError.invalidResponse }
            if json["evt"] as? String == "ERROR" {
                // Ignore unrelated delayed events, but never mistake an error for a confirmation.
                if matching(json) || json["nonce"] == nil {
                    throw IPCError.rejected(
                        (json["data"] as? [String: Any])?["message"] as? String ?? "Request rejected")
                }
            }
            if matching(json) { return json }
        }
        throw IPCError.timeout
    }
    // Tests inject a local socket pair; production always performs Discord's READY handshake.
    func attachForTesting(_ descriptor: Int32) {
        disconnect()
        fd = descriptor
        configure(fd)
        connected = true
    }
}
