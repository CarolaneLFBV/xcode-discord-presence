import Foundation
import XCTest

@testable import PresenceCore

final class PresencePublisherTests: XCTestCase {
    private let clientID = "123456789012345678"

    func testPauseWhileConnectingPreventsObsoletePublication() throws {
        let connected = expectation(description: "connect started")
        let resume = DispatchSemaphore(value: 0)
        let transport = RecordingTransport()
        transport.onConnect = {
            connected.fulfill()
            _ = resume.wait(timeout: .now() + 3)
        }
        let publisher = PresencePublisher(transport: transport)
        let obsolete = expectation(description: "obsolete request cancelled")
        publisher.publish(clientID: clientID, activityJSON: try payload("Original.swift")) { result in
            guard case .cancelled = result else { return XCTFail("Expected cancellation") }
            obsolete.fulfill()
        }
        wait(for: [connected], timeout: 2)
        publisher.invalidate()
        let clear = expectation(description: "pause applied")
        publisher.publish(clientID: clientID, activityJSON: nil) { result in
            guard case .cleared = result else { return XCTFail("Expected clear") }
            clear.fulfill()
        }
        resume.signal()
        wait(for: [obsolete, clear], timeout: 3)
        XCTAssertEqual(transport.events, ["connect", "clear"])
    }

    func testLatestSettingsReplaceAStillConnectingRequest() throws {
        let connected = expectation(description: "connect started")
        let resume = DispatchSemaphore(value: 0)
        let transport = RecordingTransport()
        transport.onConnect = {
            connected.fulfill()
            _ = resume.wait(timeout: .now() + 3)
        }
        let publisher = PresencePublisher(transport: transport)
        publisher.publish(clientID: clientID, activityJSON: try payload("PrivateFile.swift")) { _ in }
        wait(for: [connected], timeout: 2)
        transport.onConnect = nil
        let updated = expectation(description: "new privacy settings published")
        publisher.publish(clientID: clientID, activityJSON: try payload("Developing in Xcode")) { result in
            guard case .confirmed = result else { return XCTFail("Expected confirmation") }
            updated.fulfill()
        }
        resume.signal()
        wait(for: [updated], timeout: 3)
        XCTAssertFalse(transport.events.contains("PrivateFile.swift"))
        XCTAssertEqual(transport.events.last, "Developing in Xcode")
    }

    func testFailureDisconnectsAndNextRequestReconnects() throws {
        let transport = RecordingTransport()
        transport.failNextPublication = true
        let publisher = PresencePublisher(transport: transport)
        let failed = expectation(description: "failure reported")
        publisher.publish(clientID: clientID, activityJSON: try payload("First.swift")) { result in
            guard case .failed = result else { return XCTFail("Expected failure") }
            failed.fulfill()
        }
        wait(for: [failed], timeout: 2)
        let recovered = expectation(description: "retry confirmed")
        publisher.publish(clientID: clientID, activityJSON: try payload("Second.swift")) { result in
            guard case .confirmed = result else { return XCTFail("Expected recovery") }
            recovered.fulfill()
        }
        wait(for: [recovered], timeout: 2)
        XCTAssertEqual(transport.events, ["connect", "disconnect", "connect", "Second.swift"])
    }

    func testClientIDChangeAndShutdownClearPreviousActivity() throws {
        let transport = RecordingTransport()
        let publisher = PresencePublisher(transport: transport)
        for id in [clientID, "987654321098765432"] {
            let confirmed = expectation(description: "activity confirmed")
            publisher.publish(clientID: id, activityJSON: try payload("File.swift")) { _ in
                confirmed.fulfill()
            }
            wait(for: [confirmed], timeout: 2)
        }
        let stopped = expectation(description: "shutdown finished")
        publisher.shutdown { stopped.fulfill() }
        wait(for: [stopped], timeout: 2)
        XCTAssertEqual(
            transport.events,
            ["connect", "File.swift", "clear", "disconnect", "connect", "File.swift", "clear", "disconnect"])
    }

    private func payload(_ details: String) throws -> Data {
        try JSONSerialization.data(withJSONObject: ["details": details])
    }
}

/// Calls are made only by the publisher's serial queue. Tests inspect the log
/// after the completion expectation establishes ordering with that queue.
private final class RecordingTransport: DiscordTransport {
    var connected = false
    var events: [String] = []
    var onConnect: (() -> Void)?
    var failNextPublication = false

    func connect(clientID: String) throws {
        guard !connected else { return }
        events.append("connect")
        onConnect?()
        connected = true
    }

    func setActivity(_ activity: [String: Any]?) throws -> Date {
        if failNextPublication {
            failNextPublication = false
            throw IPCError.disconnected
        }
        events.append(activity?["details"] as? String ?? "clear")
        return Date()
    }

    func disconnect() {
        events.append("disconnect")
        connected = false
    }
}
