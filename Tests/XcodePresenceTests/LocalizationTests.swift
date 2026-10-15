import PresenceCore
import XCTest

@testable import XcodePresence

final class LocalizationTests: XCTestCase {
    func testAllKeysHaveFrenchTranslations() {
        let french = AppLocalizer(language: .fr)
        let sharedText: Set<AppText> = [.pause]
        for key in AppText.allCases {
            XCTAssertFalse(french.text(key).isEmpty)
            if !sharedText.contains(key) {
                XCTAssertNotEqual(french.text(key), key.rawValue, "Missing French translation: \(key)")
            }
        }
    }

    func testInactivityFormattingAndRetainedFileStatus() {
        XCTAssertTrue(AppLocalizer(language: .fr).inactivityMessage(minutes: 15).contains("15 minutes"))
        XCTAssertTrue(AppLocalizer(language: .en).inactivityMessage(minutes: 5).contains("5 minutes"))
        let status = PresenceStatusText(
            phase: .live, language: .en, retainingFile: true,
            idleMinutes: 0, connectionError: "")
        XCTAssertEqual(status.title, "Your activity is being shared")
        XCTAssertTrue(status.subtitle.contains("Keeping the last file"))
    }
}
