import Foundation

public struct ActivityPresentation {
    public let title: String
    public let details: String
    public let state: String
    public let language: CodeLanguage
    public let showLanguage: Bool
    public let start: Date?
    public init(
        editor: String, file: EditorFile, options: SharingOptions, language: AppLanguage, start: Date?
    ) {
        title = editor
        self.language = CodeLanguage.detect(file: file.name, french: language.isFrench)
        details =
            options.file
            ? language.text("Editing ", "Édition de ") + file.name
            : language.text("Developing in Xcode", "Développement sur Xcode")
        state = [options.language ? self.language.name : nil, options.project ? file.project : nil].compactMap
        { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
        showLanguage = options.language
        self.start = options.elapsed ? start : nil
    }
    /// Whitelist only public display fields. Never serialize file URLs or editor contents.
    public var payload: [String: Any] {
        var result: [String: Any] = ["name": title, "type": 0, "details": String(details.prefix(128))]
        if !state.isEmpty { result["state"] = String(state.prefix(128)) }
        var assets = [
            "large_image": "https://developer.apple.com/assets/elements/icons/xcode-s/xcode-s-96x96_2x.png",
            "large_text": title,
        ]
        if showLanguage, let icon = language.remoteIcon {
            assets["small_image"] = icon
            assets["small_text"] = language.name
        }
        result["assets"] = assets
        if let start { result["timestamps"] = ["start": Int(start.timeIntervalSince1970)] }
        return result
    }
}
