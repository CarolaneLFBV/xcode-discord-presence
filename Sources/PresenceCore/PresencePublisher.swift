import Foundation

/// Implementations are owned exclusively by PresencePublisher's serial queue.
public protocol DiscordTransport: AnyObject {
    var connected: Bool { get }
    func connect(clientID: String) throws
    func setActivity(_ activity: [String: Any]?) throws -> Date
    func disconnect()
}

public enum PublicationResult: Sendable {
    case confirmed(Date)
    case cleared
    case cancelled
    case failed(String)
}

/// Serializes transport operations and invalidates queued or still-connecting
/// requests synchronously. A frame already sent to Discord cannot be recalled;
/// the next clear/update runs as soon as that bounded operation finishes.
///
/// The unchecked conformance is confined here: the transport is queue-owned and
/// the only cross-queue mutable value (revision) is protected by revisionLock.
public final class PresencePublisher: @unchecked Sendable {
    private let queue = DispatchQueue(label: "XcodePresence.publisher", qos: .utility)
    private let transport: DiscordTransport
    private let revisionLock = NSLock()
    private var revision: UInt64 = 0
    private var connectedClientID: String?

    public init(transport: DiscordTransport = DiscordIPC()) {
        self.transport = transport
    }

    public func invalidate() {
        revisionLock.lock()
        revision &+= 1
        revisionLock.unlock()
    }

    public func publish(
        clientID: String,
        activityJSON: Data?,
        completion: @escaping @Sendable (PublicationResult) -> Void
    ) {
        revisionLock.lock()
        revision &+= 1
        let ticket = revision
        revisionLock.unlock()

        queue.async { [self] in
            guard isCurrent(ticket) else {
                completion(.cancelled)
                return
            }
            do {
                if let activityJSON {
                    guard
                        let activity = try JSONSerialization.jsonObject(with: activityJSON) as? [String: Any]
                    else {
                        throw IPCError.invalidResponse
                    }
                    if transport.connected && connectedClientID != clientID {
                        _ = try transport.setActivity(nil)
                        transport.disconnect()
                    }
                    guard isCurrent(ticket) else {
                        completion(.cancelled)
                        return
                    }
                    try transport.connect(clientID: clientID)
                    connectedClientID = clientID
                    // A pause/privacy change may arrive while READY is pending.
                    guard isCurrent(ticket) else {
                        completion(.cancelled)
                        return
                    }
                    let confirmed = try transport.setActivity(activity)
                    completion(isCurrent(ticket) ? .confirmed(confirmed) : .cancelled)
                } else {
                    if transport.connected {
                        _ = try transport.setActivity(nil)
                    }
                    completion(isCurrent(ticket) ? .cleared : .cancelled)
                }
            } catch {
                transport.disconnect()
                connectedClientID = nil
                completion(isCurrent(ticket) ? .failed(error.localizedDescription) : .cancelled)
            }
        }
    }

    public func reset() {
        invalidate()
        queue.async { [self] in
            transport.disconnect()
            connectedClientID = nil
        }
    }

    public func shutdown(completion: @escaping @Sendable () -> Void) {
        invalidate()
        queue.async { [self] in
            if transport.connected {
                _ = try? transport.setActivity(nil)
            }
            transport.disconnect()
            connectedClientID = nil
            completion()
        }
    }

    private func isCurrent(_ ticket: UInt64) -> Bool {
        revisionLock.lock()
        defer { revisionLock.unlock() }
        return revision == ticket
    }
}
