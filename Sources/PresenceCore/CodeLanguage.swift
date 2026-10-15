import Foundation

public struct CodeLanguage: Equatable {
    public let name: String
    public let icon: String?
    public init(_ name: String, _ icon: String? = nil) {
        self.name = name
        self.icon = icon
    }
    public static func detect(file: String, french: Bool = false) -> CodeLanguage {
        switch (file as NSString).pathExtension.lowercased() {
        case "swift": return .init("Swift", "swift")
        case "m", "mm": return .init("Objective-C", "objective-c")
        case "h": return .init(french ? "En-tête C / Objective-C" : "C / Objective-C header", "c")
        case "c": return .init("C", "c")
        case "cc", "cpp", "cxx", "hpp", "hh": return .init("C++", "cpp")
        case "js", "jsx", "mjs", "cjs": return .init("JavaScript", "javascript")
        case "ts", "tsx": return .init("TypeScript", "typescript")
        case "py": return .init("Python", "python")
        case "rb": return .init("Ruby", "ruby")
        case "sh", "bash", "zsh": return .init("Shell", "bash")
        case "html", "htm": return .init("HTML", "html")
        case "css", "scss", "sass": return .init("CSS", "css")
        case "json", "xcassets": return .init("JSON", "json")
        case "xml", "plist", "storyboard", "xib", "entitlements", "xcprivacy": return .init("XML", "xml")
        case "yaml", "yml": return .init("YAML", "yaml")
        case "md", "markdown": return .init("Markdown", "markdown")
        case "xcconfig", "pbxproj": return .init(french ? "Configuration Xcode" : "Xcode configuration")
        case "metal": return .init("Metal")
        case "kt", "kts": return .init("Kotlin")
        case "rs": return .init("Rust")
        case "go": return .init("Go")
        default: return .init((file as NSString).pathExtension.uppercased())
        }
    }
    public var remoteIcon: String? {
        guard let icon else { return nil }
        return
            "https://raw.githubusercontent.com/github/explore/4a3fe88f59d2a20ea3a1a12b4bbf8cf1f1d34670/topics/\(icon)/\(icon).png"
    }
}
