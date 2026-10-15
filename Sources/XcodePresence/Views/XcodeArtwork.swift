import AppKit

/// Resolve Apple's artwork from the user's installed application instead of
/// redistributing an Apple bitmap as part of this project's source or binary.
enum XcodeArtwork {
    static let image: NSImage = {
        let stable = URL(fileURLWithPath: "/Applications/Xcode.app")
        let installed =
            FileManager.default.fileExists(atPath: stable.path)
            ? stable
            : NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.dt.Xcode")
        if let installed {
            return NSWorkspace.shared.icon(forFile: installed.path)
        }
        return NSImage(systemSymbolName: "hammer", accessibilityDescription: "Xcode") ?? NSImage()
    }()
}
