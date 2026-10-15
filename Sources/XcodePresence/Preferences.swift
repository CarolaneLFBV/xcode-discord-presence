import Foundation
import PresenceCore

struct Preferences: Equatable {
    var language: AppLanguage = .system
    var showFile = true
    var showProject = true
    var showLanguage = true
    var showElapsed = true
    var focusOnly = false
    var idleMinutes = 0
    var paused = false
    var clientID = ""
}

/// Stable keys preserve settings from earlier local versions of the application.
struct PreferenceStore {
    let defaults: UserDefaults

    func load() -> Preferences {
        defaults.register(defaults: [
            "showFile": true,
            "showProject": true,
            "showLanguage": true,
            "showElapsed": true,
            "focusOnly": false,
            "idleMinutes": 0,
            "paused": false,
            "appLanguage": AppLanguage.system.rawValue,
        ])
        var preferences = Preferences()
        preferences.language = AppLanguage(rawValue: defaults.string(forKey: "appLanguage") ?? "") ?? .system
        preferences.showFile = defaults.bool(forKey: "showFile")
        preferences.showProject = defaults.bool(forKey: "showProject")
        preferences.showLanguage = defaults.bool(forKey: "showLanguage")
        preferences.showElapsed = defaults.bool(forKey: "showElapsed")
        preferences.focusOnly = defaults.bool(forKey: "focusOnly")
        preferences.paused = defaults.bool(forKey: "paused")
        let minutes = defaults.integer(forKey: "idleMinutes")
        preferences.idleMinutes = [0, 5, 15, 30].contains(minutes) ? minutes : 0
        preferences.clientID = defaults.string(forKey: "clientID") ?? ""
        return preferences
    }

    func save(_ preferences: Preferences) {
        defaults.set(preferences.language.rawValue, forKey: "appLanguage")
        defaults.set(preferences.showFile, forKey: "showFile")
        defaults.set(preferences.showProject, forKey: "showProject")
        defaults.set(preferences.showLanguage, forKey: "showLanguage")
        defaults.set(preferences.showElapsed, forKey: "showElapsed")
        defaults.set(preferences.focusOnly, forKey: "focusOnly")
        defaults.set(preferences.idleMinutes, forKey: "idleMinutes")
        defaults.set(preferences.paused, forKey: "paused")
        defaults.set(preferences.clientID, forKey: "clientID")
    }
}
