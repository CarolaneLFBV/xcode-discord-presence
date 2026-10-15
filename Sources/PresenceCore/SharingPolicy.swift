import Foundation

public enum PresencePhase {
    case checking, setup, permission, waitingXcode, waitingFile, foreground, idle, paused, connecting, live,
        failed, preview
}

public enum SharingPolicy {
    public static func phase(
        paused: Bool, validID: Bool, trusted: Bool, running: Bool,
        focusOnly: Bool, foreground: Bool, idleMinutes: Int,
        idleSeconds: TimeInterval, hasFile: Bool
    ) -> PresencePhase {
        if paused { return .paused }
        if !validID { return .setup }
        if !trusted { return .permission }
        if !running { return .waitingXcode }
        if focusOnly && !foreground { return .foreground }
        if idleMinutes > 0 && idleSeconds >= Double(idleMinutes * 60) { return .idle }
        if !hasFile { return .waitingFile }
        return .connecting
    }
}
