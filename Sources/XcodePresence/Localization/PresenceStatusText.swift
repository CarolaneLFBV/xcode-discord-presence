import PresenceCore

struct PresenceStatusText {
    let phase: PresencePhase
    let language: AppLanguage
    let retainingFile: Bool
    let idleMinutes: Int
    let connectionError: String
    var localizer: AppLocalizer { AppLocalizer(language: language) }
    func text(_ key: AppText) -> String { localizer.text(key) }
    var title: String {
        switch phase {
        case .checking: return text(.checking)
        case .setup: return text(.letSConnectDiscord)
        case .permission: return text(.permissionNeeded)
        case .waitingXcode: return text(.waitingForXcode)
        case .waitingFile: return text(.waitingForAFile)
        case .foreground: return text(.xcodeIsInTheBackground)
        case .idle: return text(.pausedDueToInactivity)
        case .paused: return text(.sharingIsPaused)
        case .connecting: return text(.connectingToDiscord)
        case .failed: return text(.checkYourConnection)
        case .live: return text(.yourActivityIsBeingShared)
        case .preview: return text(.designPreview)
        }
    }
    var subtitle: String {
        switch phase {
        case .checking, .connecting: return text(.readingXcodeAndConnectingToDiscord)
        case .setup: return text(.addYourApplicationIDInConnection)
        case .permission: return text(.allowXcodePresenceInMacOSPrivacySettings)
        case .waitingXcode: return text(.openXcodeOrXcodeBetaToGetStarted)
        case .waitingFile: return text(.missingDocumentExplanation)
        case .foreground: return text(.foregroundOnlyExplanation)
        case .idle: return localizer.inactivityMessage(minutes: idleMinutes)
        case .paused: return text(.resumeSharingWheneverYouLike)
        case .failed: return localizedError
        case .live:
            return retainingFile
                ? text(
                    .retainedFileExplanation)
                : text(.discordConfirmedReceiptOfThisActivity)
        case .preview: return text(.sampleDataNoActivityIsSentToDiscord)
        }
    }
    private var localizedError: String {
        if language.isFrench {
            if connectionError.contains("not found") {
                return "Discord introuvable : ouvre l’application Discord sur ce Mac."
            }
            if connectionError.contains("disconnected") {
                return "Discord déconnecté. Nouvelle tentative automatique."
            }
            if connectionError.contains("responding") {
                return "Discord ne répond pas. Nouvelle tentative automatique."
            }
        }
        return connectionError
    }
}
