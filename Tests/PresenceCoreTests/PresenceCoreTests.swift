import Darwin
import XCTest

@testable import PresenceCore

final class PresenceCoreTests: XCTestCase {
    private let sample = EditorFile(
        url: URL(fileURLWithPath: "/private/SecretProject/Sources/Hello.swift"), project: "SecretProject")
    func testRetainsFileInAgenticPanelWithoutRestartingTimer() {
        var session = EditorSession()
        let start = Date(timeIntervalSince1970: 100)
        session.update(pid: 123, file: sample, now: start)
        session.update(pid: 123, file: nil, now: start.addingTimeInterval(100))
        XCTAssertEqual(session.file, sample)
        XCTAssertTrue(session.retainingFile)
        XCTAssertEqual(session.start, start)
        let next = EditorFile(url: URL(fileURLWithPath: "/Other/File.py"), project: "Other")
        session.update(pid: 123, file: next)
        XCTAssertEqual(session.file, next)
        XCTAssertFalse(session.retainingFile)
        XCTAssertEqual(session.start, start)
    }
    func testExitAndNewProcessForgetPreviousFile() {
        var session = EditorSession()
        session.update(pid: 1, file: sample)
        session.update(pid: 2, file: nil)
        XCTAssertNil(session.file)
        XCTAssertFalse(session.retainingFile)
        session.update(pid: nil, file: nil)
        XCTAssertNil(session.pid)
        XCTAssertNil(session.start)
    }
    func testPrivacyOptionsRemoveNamesLanguageAndTimestamp() throws {
        var options = SharingOptions()
        options.file = false
        options.project = false
        options.language = false
        options.elapsed = false
        let activity = ActivityPresentation(
            editor: "Xcode Beta 27.2", file: sample, options: options, language: .en, start: Date())
        let json = String(
            data: try JSONSerialization.data(withJSONObject: activity.payload), encoding: .utf8)!
        for secret in [
            "Hello.swift", "SecretProject", "Swift", "/private", "timestamps", "small_image", "small_text",
        ] { XCTAssertFalse(json.contains(secret), secret) }
        XCTAssertEqual(activity.details, "Developing in Xcode")
        XCTAssertEqual(activity.state, "")
    }
    func testEnabledFieldsNeverIncludePath() throws {
        let activity = ActivityPresentation(
            editor: "Xcode Beta 27.2", file: sample, options: SharingOptions(), language: .fr,
            start: Date(timeIntervalSince1970: 123456))
        let json = String(
            data: try JSONSerialization.data(withJSONObject: activity.payload), encoding: .utf8)!
        XCTAssertFalse(json.contains("/private"))
        XCTAssertEqual(activity.details, "Édition de Hello.swift")
        XCTAssertEqual(activity.state, "Swift · SecretProject")
        XCTAssertEqual((activity.payload["timestamps"] as? [String: Int])?["start"], 123456)
    }
    func testIndividualPrivacySwitches() {
        for choice in 0..<4 {
            var options = SharingOptions()
            switch choice {
            case 0: options.file = false
            case 1: options.project = false
            case 2: options.language = false
            default: options.elapsed = false
            }
            let activity = ActivityPresentation(
                editor: "Xcode", file: sample, options: options, language: .en, start: Date())
            if choice == 0 { XCTAssertFalse(activity.details.contains("Hello.swift")) }
            if choice == 1 { XCTAssertFalse(activity.state.contains("SecretProject")) }
            if choice == 2 {
                XCTAssertFalse(activity.state.contains("Swift"))
                XCTAssertNil((activity.payload["assets"] as? [String: String])?["small_image"])
            }
            if choice == 3 { XCTAssertNil(activity.payload["timestamps"]) }
        }
    }
    func testLanguageDetectionAndUnknownIcon() {
        XCTAssertEqual(CodeLanguage.detect(file: "Main.SWIFT").icon, "swift")
        XCTAssertEqual(CodeLanguage.detect(file: "App.mm").name, "Objective-C")
        XCTAssertEqual(CodeLanguage.detect(file: "config.plist").icon, "xml")
        XCTAssertEqual(CodeLanguage.detect(file: "App.tsx").icon, "typescript")
        XCTAssertNil(CodeLanguage.detect(file: "secret.unknown").icon)
        XCTAssertEqual(
            CodeLanguage.detect(file: "App.swift").remoteIcon,
            "https://raw.githubusercontent.com/github/explore/4a3fe88f59d2a20ea3a1a12b4bbf8cf1f1d34670/topics/swift/swift.png"
        )
    }
    func testXcodeVersionIsProductVersionNotBetaIndex() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let app = root.appendingPathComponent("Xcode-beta.app")
        try FileManager.default.createDirectory(
            at: app.appendingPathComponent("Contents"), withIntermediateDirectories: true)
        let data = try PropertyListSerialization.data(
            fromPropertyList: ["CFBundleShortVersionString": "27.2"], format: .xml, options: 0)
        try data.write(to: app.appendingPathComponent("Contents/Info.plist"))
        XCTAssertEqual(XcodeVersion.title(appURL: app), "Xcode Beta 27.2")
    }
    func testInvalidClientIDs() {
        XCTAssertTrue(DiscordIPC.validClientID("1234567890123456789"))
        for id in [
            "", "token.not.an.id", "123456789012345678a", "１２３４５６７８９０１２３４５６７", "123", "123456789012345678901",
        ] { XCTAssertFalse(DiscordIPC.validClientID(id)) }
    }
    func testSharingStopsForPausePermissionAndMissingFile() {
        XCTAssertEqual(policy(paused: true), .paused)
        XCTAssertEqual(policy(validID: false), .setup)
        XCTAssertEqual(policy(trusted: false), .permission)
        XCTAssertEqual(policy(running: false), .waitingXcode)
        XCTAssertEqual(policy(hasFile: false), .waitingFile)
        XCTAssertEqual(policy(), .connecting)
    }
    func testForegroundAndIdleSharingRules() {
        XCTAssertEqual(policy(focusOnly: false, foreground: false), .connecting)
        XCTAssertEqual(policy(focusOnly: true, foreground: false), .foreground)
        XCTAssertEqual(policy(focusOnly: true, foreground: true), .connecting)
        XCTAssertEqual(policy(idleMinutes: 0, idleSeconds: 999_999), .connecting)
        for minutes in [5, 15, 30] {
            XCTAssertEqual(policy(idleMinutes: minutes, idleSeconds: Double(minutes * 60 - 1)), .connecting)
            XCTAssertEqual(policy(idleMinutes: minutes, idleSeconds: Double(minutes * 60)), .idle)
        }
    }
    private func policy(
        paused: Bool = false, validID: Bool = true, trusted: Bool = true,
        running: Bool = true, focusOnly: Bool = false, foreground: Bool = true,
        idleMinutes: Int = 0, idleSeconds: Double = 0, hasFile: Bool = true
    ) -> PresencePhase {
        SharingPolicy.phase(
            paused: paused, validID: validID, trusted: trusted, running: running,
            focusOnly: focusOnly, foreground: foreground, idleMinutes: idleMinutes,
            idleSeconds: idleSeconds, hasFile: hasFile)
    }
    func testFragmentedRepliesAndPingPong() throws {
        var fds: [Int32] = [0, 0]
        XCTAssertEqual(socketpair(AF_UNIX, SOCK_STREAM, 0, &fds), 0)
        let ipc = DiscordIPC()
        ipc.attachForTesting(fds[0])
        let done = expectation(description: "server received pong and command")
        DispatchQueue.global().async {
            defer {
                Darwin.close(fds[1])
                done.fulfill()
            }
            do {
                let command = try self.readFrame(fds[1])
                let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: command.1) as? [String: Any])
                XCTAssertEqual(json["cmd"] as? String, "SET_ACTIVITY")
                XCTAssertTrue((json["args"] as? [String: Any])?["activity"] is NSNull)
                try self.writeFrame(fds[1], opcode: 3, data: Data("ping".utf8), fragmented: true)
                let pong = try self.readFrame(fds[1])
                XCTAssertEqual(pong.0, 4)
                XCTAssertEqual(pong.1, Data("ping".utf8))
                let reply = try JSONSerialization.data(withJSONObject: [
                    "cmd": "SET_ACTIVITY", "nonce": json["nonce"]!, "data": NSNull(),
                ])
                try self.writeFrame(fds[1], opcode: 1, data: reply, fragmented: true)
            } catch { XCTFail("\(error)") }
        }
        _ = try ipc.setActivity(nil)
        wait(for: [done], timeout: 5)
    }
    func testRPCErrorDoesNotCountAsConfirmation() throws {
        var fds: [Int32] = [0, 0]
        XCTAssertEqual(socketpair(AF_UNIX, SOCK_STREAM, 0, &fds), 0)
        let ipc = DiscordIPC()
        ipc.attachForTesting(fds[0])
        let done = expectation(description: "error reply")
        DispatchQueue.global().async {
            defer {
                Darwin.close(fds[1])
                done.fulfill()
            }
            do {
                let command = try self.readFrame(fds[1])
                let json = try JSONSerialization.jsonObject(with: command.1) as! [String: Any]
                try self.writeFrame(
                    fds[1], opcode: 1,
                    data: JSONSerialization.data(withJSONObject: [
                        "cmd": "SET_ACTIVITY", "evt": "ERROR", "nonce": json["nonce"]!,
                        "data": ["message": "Rejected test"],
                    ]))
            } catch { XCTFail("\(error)") }
        }
        XCTAssertThrowsError(try ipc.setActivity(nil)) {
            XCTAssertTrue($0.localizedDescription.contains("Rejected test"))
        }
        XCTAssertFalse(ipc.connected)
        wait(for: [done], timeout: 5)
    }
    func testOversizedFrameIsRejectedBeforeAllocation() throws {
        var fds: [Int32] = [0, 0]
        XCTAssertEqual(socketpair(AF_UNIX, SOCK_STREAM, 0, &fds), 0)
        defer { Darwin.close(fds[1]) }
        let ipc = DiscordIPC()
        ipc.attachForTesting(fds[0])
        var header: [UInt32] = [1, UInt32.max]
        _ = header.withUnsafeMutableBytes { Darwin.write(fds[1], $0.baseAddress, $0.count) }
        XCTAssertThrowsError(try ipc.setActivity(nil)) { XCTAssertTrue($0 is IPCError) }
    }
    private func readFrame(_ fd: Int32) throws -> (UInt32, Data) {
        func read(_ count: Int) throws -> Data {
            var result = Data(count: count)
            try result.withUnsafeMutableBytes { bytes in
                var offset = 0
                while offset < count {
                    var pollfd = pollfd(fd: fd, events: Int16(POLLIN), revents: 0)
                    guard Darwin.poll(&pollfd, 1, 4000) > 0 else { throw IPCError.timeout }
                    let n = Darwin.read(fd, bytes.baseAddress!.advanced(by: offset), count - offset)
                    guard n > 0 else { throw IPCError.disconnected }
                    offset += n
                }
            }
            return result
        }
        let header = try read(8)
        let op = header.withUnsafeBytes { $0.loadUnaligned(as: UInt32.self) }
        let size = header.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: 4, as: UInt32.self) }
        return (op, try read(Int(size)))
    }
    private func writeFrame(_ fd: Int32, opcode: UInt32, data: Data, fragmented: Bool = false) throws {
        var header = [opcode.littleEndian, UInt32(data.count).littleEndian]
        var frame = header.withUnsafeMutableBytes { Data($0) }
        frame.append(data)
        try frame.withUnsafeBytes { bytes in
            var offset = 0
            while offset < bytes.count {
                let n = Darwin.write(
                    fd, bytes.baseAddress!.advanced(by: offset), fragmented ? 1 : bytes.count - offset)
                guard n > 0 else { throw IPCError.disconnected }
                offset += n
            }
        }
    }
}
