import Foundation

public enum XcodeVersion {
    /// Xcode's 27.2 is its product version, never a beta sequence number.
    public static func title(appURL: URL) -> String {
        let data = try? Data(contentsOf: appURL.appendingPathComponent("Contents/Info.plist"))
        let info =
            data.flatMap { try? PropertyListSerialization.propertyList(from: $0, format: nil) }
            as? [String: Any] ?? [:]
        let version = info["CFBundleShortVersionString"] as? String ?? ""
        let beta =
            appURL.lastPathComponent.lowercased().contains("beta")
            || (info["CFBundleIconName"] as? String ?? "").lowercased().contains("beta")
        return [beta ? "Xcode Beta" : "Xcode", version].filter { !$0.isEmpty }.joined(separator: " ")
    }
}
