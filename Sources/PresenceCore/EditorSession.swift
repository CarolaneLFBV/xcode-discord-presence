import Foundation

public struct EditorFile: Equatable {
    public let url: URL
    public let project: String?
    public var name: String { url.lastPathComponent }
    public init(url: URL, project: String?) {
        self.url = url
        self.project = project
    }
}

/// Retain a file across documentless panels, but never across Xcode processes or launches.
public struct EditorSession {
    public private(set) var pid: Int32?
    public private(set) var start: Date?
    public private(set) var file: EditorFile?
    public private(set) var retainingFile = false
    public init() {}
    public mutating func update(pid: Int32?, file: EditorFile?, now: Date = Date()) {
        guard let pid else {
            self = EditorSession()
            return
        }
        if self.pid != pid {
            self.pid = pid
            start = now
            self.file = nil
        }
        retainingFile = file == nil && self.file != nil
        if let file { self.file = file }
    }
}
