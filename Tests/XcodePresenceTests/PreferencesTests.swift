import Foundation
import PresenceCore
import XCTest

@testable import XcodePresence

final class PreferencesTests: XCTestCase {
    func testFreshInstallDefaultsAndRoundTrip() throws {
        let name = "XcodePresenceTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = PreferenceStore(defaults: defaults)
        XCTAssertEqual(store.load(), Preferences())
        var preferences = Preferences()
        preferences.language = .fr
        preferences.clientID = "123456789012345678"
        preferences.showFile = false
        preferences.focusOnly = true
        preferences.idleMinutes = 15
        preferences.paused = true
        store.save(preferences)
        XCTAssertEqual(store.load(), preferences)
    }

    func testExistingKeysAndUnsupportedValues() throws {
        let name = "XcodePresenceTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set("unknown", forKey: "appLanguage")
        defaults.set(999, forKey: "idleMinutes")
        defaults.set(false, forKey: "showLanguage")
        defaults.set("123456789012345678", forKey: "clientID")
        let preferences = PreferenceStore(defaults: defaults).load()
        XCTAssertEqual(preferences.language, .system)
        XCTAssertEqual(preferences.idleMinutes, 0)
        XCTAssertFalse(preferences.showLanguage)
        XCTAssertEqual(preferences.clientID, "123456789012345678")
    }
}
