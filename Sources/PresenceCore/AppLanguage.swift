import Foundation

public enum AppLanguage: String, CaseIterable {
    case system, fr, en
    public var isFrench: Bool {
        if self != .system { return self == .fr }
        return Locale.preferredLanguages.first(where: { $0.hasPrefix("fr") || $0.hasPrefix("en") })?
            .hasPrefix("fr") ?? false
    }
    public func text(_ english: String, _ french: String) -> String { isFrench ? french : english }
}
