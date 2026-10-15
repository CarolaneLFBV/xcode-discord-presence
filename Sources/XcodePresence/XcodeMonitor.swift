import AppKit
import ApplicationServices
import PresenceCore

struct XcodeReading {
    var pid: Int32?
    var editor = "Xcode"
    var file: EditorFile?
    var foreground = false
    var trusted = false
}

enum XcodeMonitor {
    static func runningApp(preferredPID: Int32?) -> NSRunningApplication? {
        let apps = NSWorkspace.shared.runningApplications.filter {
            $0.bundleIdentifier == "com.apple.dt.Xcode" && !$0.isTerminated
        }
        return apps.first(where: \.isActive) ?? apps.first(where: { $0.processIdentifier == preferredPID })
            ?? apps.first
    }
    /// Read document metadata only, never AXValue on the source editor.
    static func read(app: NSRunningApplication?) -> XcodeReading {
        var result = XcodeReading()
        result.trusted = AXIsProcessTrusted()
        guard let app else { return result }
        result.pid = app.processIdentifier
        result.foreground = app.isActive
        if let url = app.bundleURL { result.editor = XcodeVersion.title(appURL: url) }
        guard result.trusted else { return result }
        let deadline = Date().addingTimeInterval(1.5)
        let application = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(application, 0.25)
        let focused = element(application, kAXFocusedWindowAttribute)
        let windows = (attribute(application, kAXWindowsAttribute) as? [AXUIElement]) ?? []
        // Do not use unrelated background windows while the focused window is a documentless panel.
        let candidates = focused.map { [$0] } ?? Array(windows.prefix(1))
        for window in candidates {
            guard Date() < deadline else { break }
            let title = attribute(window, kAXTitleAttribute) as? String ?? ""
            var document = fileURL(attribute(window, kAXDocumentAttribute))
            if document == nil, let focus = element(application, kAXFocusedUIElementAttribute) {
                var node: AXUIElement? = focus
                for _ in 0..<8 {
                    guard Date() < deadline else { break }
                    guard let current = node else { break }
                    document =
                        fileURL(attribute(current, kAXDocumentAttribute))
                        ?? fileURL(attribute(current, kAXURLAttribute))
                    if document != nil { break }
                    node = element(current, kAXParentAttribute)
                }
            }
            if document == nil {
                var budget = 180
                document = findDocument(window, depth: 0, budget: &budget, deadline: deadline)
            }
            if let document, !["xcodeproj", "xcworkspace"].contains(document.pathExtension) {
                result.file = EditorFile(url: document, project: projectName(file: document, title: title))
                break
            }
        }
        return result
    }
    private static func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }
    private static func element(_ source: AXUIElement, _ name: String) -> AXUIElement? {
        guard let value = attribute(source, name), CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }
        return (value as! AXUIElement)
    }
    private static func fileURL(_ value: CFTypeRef?) -> URL? {
        let url: URL?
        if let actual = value as? URL {
            url = actual
        } else if let string = value as? String {
            url =
                string.hasPrefix("file:")
                ? URL(string: string) : (string.hasPrefix("/") ? URL(fileURLWithPath: string) : nil)
        } else {
            url = nil
        }
        guard let url, url.isFileURL, !url.lastPathComponent.isEmpty else { return nil }
        return url.standardizedFileURL
    }
    private static func findDocument(_ node: AXUIElement, depth: Int, budget: inout Int, deadline: Date)
        -> URL?
    {
        guard depth < 9, budget > 0, Date() < deadline else { return nil }
        budget -= 1
        let role = attribute(node, kAXRoleAttribute) as? String ?? ""
        if let url = fileURL(attribute(node, kAXDocumentAttribute)),
            !["xcodeproj", "xcworkspace"].contains(url.pathExtension)
        {
            return url
        }
        // Only inspect a source editor's URL, not navigator rows or arbitrary links.
        if role == kAXTextAreaRole, let url = fileURL(attribute(node, kAXURLAttribute)) { return url }
        if [kAXOutlineRole, kAXTableRole].contains(role) { return nil }
        for child in (attribute(node, kAXChildrenAttribute) as? [AXUIElement]) ?? [] {
            if let url = findDocument(child, depth: depth + 1, budget: &budget, deadline: deadline) {
                return url
            }
        }
        return nil
    }
    static func projectName(file: URL, title: String) -> String? {
        if let split = title.range(of: " — ") {
            let candidate = String(title[..<split.lowerBound])
            if !candidate.isEmpty, candidate != file.lastPathComponent { return candidate }
        }
        var folder = file.deletingLastPathComponent()
        for _ in 0..<12 {
            if folder.path == "/" { break }
            let names = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
            if let project = names.sorted().first(where: { $0.hasSuffix(".xcodeproj") }) {
                return (project as NSString).deletingPathExtension
            }
            if names.contains("Package.swift") { return folder.lastPathComponent }
            folder.deleteLastPathComponent()
        }
        return nil
    }
}
