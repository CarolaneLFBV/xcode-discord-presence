import AppKit
import PresenceCore
import SwiftUI

extension PresenceModel {
    var statusColor: Color {
        switch phase {
        case .live: return .green
        case .preview: return presenceAccent
        case .paused, .idle, .foreground: return .orange
        case .failed, .permission: return .orange
        default: return .secondary
        }
    }
    var shortStatus: String {
        switch phase {
        case .live: return text(.live)
        case .preview: return text(.preview)
        case .paused, .idle, .foreground: return text(.paused)
        default: return text(.waiting)
        }
    }
}
