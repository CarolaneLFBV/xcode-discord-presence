import Combine
import Foundation
import XCTest

@testable import XcodePresence

final class PresenceModelTests: XCTestCase {
    @MainActor
    func testPreviewPreferencesRemainObservableAndPersisted() async throws {
        let name = "XcodePresenceTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set("en", forKey: "appLanguage")
        let model = PresenceModel(preview: true, defaults: defaults)
        model.refresh()
        let start = model.sessionStart
        var changes = 0
        let subscription = model.objectWillChange.sink { changes += 1 }

        model.showFile = false
        XCTAssertEqual(model.activity?.details, "Developing in Xcode")
        XCTAssertFalse(defaults.bool(forKey: "showFile"))
        XCTAssertGreaterThan(changes, 0)
        model.paused = true
        XCTAssertEqual(model.phase, .paused)
        model.paused = false
        XCTAssertEqual(model.phase, .preview)
        XCTAssertEqual(model.sessionStart, start)
        model.language = .fr
        XCTAssertEqual(model.activity?.details, "Développement sur Xcode")
        withExtendedLifetime(subscription) {}
    }

    @MainActor
    func testInvalidApplicationIDDraftDoesNotReplaceSavedID() async throws {
        let name = "XcodePresenceTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set("123456789012345678", forKey: "clientID")
        let model = PresenceModel(preview: true, defaults: defaults)
        model.clientIDDraft = "not-an-application-id"
        model.saveClientID()
        XCTAssertTrue(model.saveFailed)
        XCTAssertEqual(model.clientID, "123456789012345678")
        XCTAssertEqual(defaults.string(forKey: "clientID"), "123456789012345678")
    }
}
