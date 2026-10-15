import Foundation
import PresenceCore

enum AppText: String, CaseIterable {
    case invalidApplicationIDExplanation =
        "Paste the numeric Application ID (17–20 digits), not a token."
    case applicationIDSaved = "Application ID saved."
    case openSettings = "Open Settings…"
    case checkConnection = "Check connection"
    case reconnectToDiscord = "Reconnect to Discord"
    case resumeSharing = "Resume sharing"
    case pauseSharing = "Pause sharing"
    case gettingStarted = "Getting started…"
    case quitXcodePresence = "Quit Xcode Presence"
    case aboutXcodePresence = "About Xcode Presence"
    case settings = "Settings…"
    case hideXcodePresence = "Hide Xcode Presence"
    case edit = "Edit"
    case aboutReconstruction =
        "Reconstructed from version 0.2.7. Complete source included."
    case resume = "Resume"
    case pause = "Pause"
    case yourCodeOnDiscord = "Your code, on Discord."
    case shareYourWay = "Share your way."
    case connectToDiscord = "Connect to Discord."
    case makeItYours = "Make it yours."
    case aLiveViewOfYourCodingSession = "A live view of your coding session."
    case chooseWhatOthersCanSee = "Choose what others can see."
    case settingsAndStatusForEachConnection = "Settings and status for each connection."
    case theLanguageOfYourAppAndDiscordActivity = "The language of your app and Discord activity."
    case language = "LANGUAGE"
    case appLanguage = "App language"
    case automaticMacOS = "Automatic (macOS)"
    case alsoAppliesToTextSharedOnDiscord = "Also applies to text shared on Discord."
    case languageChangeExplanation =
        "Changes take effect immediately, without restarting."
    case live = "Live"
    case preview = "Preview"
    case paused = "Paused"
    case waiting = "Waiting"
    case discordApplication = "Discord application"
    case applicationIDExplanation =
        "The Application ID links your presence to the app created in the Discord Developer Portal."
    case save = "Save"
    case openDeveloperPortal = "Open Developer Portal ↗"
    case noDiscordTokenOrPasswordIsRequired = "No Discord token or password is required."
    case xcodeAccess = "Xcode access"
    case allowed = "Allowed"
    case permissionNeeded = "Permission needed"
    case accessibilityExplanation =
        "macOS must allow access to the active file name. Both Xcode and Xcode Beta are supported."
    case openMacOSPermissions = "Open macOS permissions"
    case permissionMigrationExplanation =
        "If access is still denied after an update, remove the old entry and add Xcode Presence again from Applications."
    case nothingShowingOnYourProfile = "Nothing showing on your profile?"
    case discordVisibilityExplanation =
        "Keep Discord for Mac open and enable activity sharing in its settings. Confirmation from Discord means the activity was received; its visibility also depends on your Discord settings."
    case checkNow = "Check now"
    case inYourMenuBarNAlwaysAClickAway = "In your menu bar.\nAlways a click away."
    case onYOURPROFILE = "ON YOUR PROFILE"
    case whenTOSHARE = "WHEN TO SHARE"
    case pauseWhenInactive = "Pause when inactive"
    case neverByDefaultPausingKeepsTheSessionTimer = "Never by default. Pausing keeps the session timer."
    case inactivity = "Inactivity"
    case never = "Never"
    case sharingPrivacyExplanation =
        "Code contents and full file paths are never shared. Changes are saved automatically."
    case macosAccess = "macOS access"
    case lastFileRetained = "Last file retained"
    case fileDetected = "File detected"
    case activityReceived = "Activity received"
    case confirmedByDiscordAt = "Confirmed by Discord at "
    case updatesAutomaticallyEvery5Seconds = "Updates automatically every 5 seconds"
    case refresh = "Refresh"
    case openConnection = "Open Connection"
    case noActivityShared = "No activity shared"
    case yourNextFileWillAppearHere = "Your next file will appear here."
    case checking = "Checking…"
    case letSConnectDiscord = "Let’s connect Discord"
    case waitingForXcode = "Waiting for Xcode"
    case waitingForAFile = "Waiting for a file"
    case xcodeIsInTheBackground = "Xcode is in the background"
    case pausedDueToInactivity = "Paused due to inactivity"
    case sharingIsPaused = "Sharing is paused"
    case connectingToDiscord = "Connecting to Discord"
    case checkYourConnection = "Check your connection"
    case yourActivityIsBeingShared = "Your activity is being shared"
    case designPreview = "Design preview"
    case readingXcodeAndConnectingToDiscord = "Reading Xcode and connecting to Discord"
    case addYourApplicationIDInConnection = "Add your Application ID in Connection."
    case allowXcodePresenceInMacOSPrivacySettings = "Allow Xcode Presence in macOS privacy settings."
    case openXcodeOrXcodeBetaToGetStarted = "Open Xcode or Xcode Beta to get started."
    case missingDocumentExplanation =
        "Xcode is open, but no saved document was detected. Select a source file in the editor."
    case foregroundOnlyExplanation =
        "Your settings allow sharing only when Xcode is in the foreground."
    case resumeSharingWheneverYouLike = "Resume sharing whenever you like."
    case retainedFileExplanation =
        "Keeping the last file while you use other Xcode panels. Selecting another file will update your presence."
    case discordConfirmedReceiptOfThisActivity = "Discord confirmed receipt of this activity."
    case sampleDataNoActivityIsSentToDiscord = "Sample data. No activity is sent to Discord."
    case undo = "Undo"
    case cut = "Cut"
    case copy = "Copy"
    case paste = "Paste"
    case selectAll = "Select All"
    case inactivityExplanation =
        "No keyboard or mouse input for %d minutes. Change this timeout in Sharing."
    case fileName = "File name"
    case fileNameExample = "For example: ContentView.swift"
    case projectName = "Project name"
    case theProjectOrPackageContainingTheFile = "The project or package containing the file"
    case languageAndIcon = "Language and icon"
    case theIconAutomaticallyMatchesTheFileType = "The icon automatically matches the file type"
    case sessionDuration = "Session duration"
    case sessionDurationExplanation =
        "Time since the Xcode session started, including pauses"
    case onlyWhenXcodeIsInTheForeground = "Only when Xcode is in the foreground"
    case otherwiseSharingContinuesInTheBackground = "Otherwise, sharing continues in the background"
    case yourActivity = "Your activity"
    case sharing = "Sharing"
    case connection = "Connection"
    case settingsLabel = "Settings"
}

struct AppLocalizer {
    let language: AppLanguage

    func text(_ key: AppText) -> String {
        language.isFrench ? Self.french[key, default: key.rawValue] : key.rawValue
    }

    func inactivityMessage(minutes: Int) -> String {
        String(format: text(.inactivityExplanation), minutes)
    }

    private static let french: [AppText: String] = [
        .invalidApplicationIDExplanation:
            "Colle l’Application ID numérique (17 à 20 chiffres), pas un token.",
        .applicationIDSaved: "Application ID enregistré.",
        .openSettings: "Ouvrir les réglages…",
        .checkConnection: "Vérifier la connexion",
        .reconnectToDiscord: "Reconnecter Discord",
        .resumeSharing: "Reprendre le partage",
        .pauseSharing: "Mettre en pause",
        .gettingStarted: "Guide de démarrage…",
        .quitXcodePresence: "Quitter Xcode Presence",
        .aboutXcodePresence: "À propos de Xcode Presence",
        .settings: "Réglages…",
        .hideXcodePresence: "Masquer Xcode Presence",
        .edit: "Édition",
        .aboutReconstruction:
            "Reconstruite à partir de la version 0.2.7. Sources complètes incluses.",
        .resume: "Reprendre",
        .pause: "Pause",
        .yourCodeOnDiscord: "Ton code, sur Discord.",
        .shareYourWay: "Partage à ta façon.",
        .connectToDiscord: "Connecte-toi à Discord.",
        .makeItYours: "À ton image.",
        .aLiveViewOfYourCodingSession: "Un aperçu de ta session, au fil de ton travail.",
        .chooseWhatOthersCanSee: "Choisis ce que les autres peuvent voir.",
        .settingsAndStatusForEachConnection: "Les réglages et l’état de chaque connexion.",
        .theLanguageOfYourAppAndDiscordActivity: "La langue de l’app et de ton activité Discord.",
        .language: "LANGUE",
        .appLanguage: "Langue de l’application",
        .automaticMacOS: "Automatique (macOS)",
        .alsoAppliesToTextSharedOnDiscord: "S’applique aussi aux textes partagés sur Discord.",
        .languageChangeExplanation: "Le changement est immédiat, sans redémarrage.",
        .live: "En direct",
        .preview: "Aperçu",
        .paused: "En pause",
        .waiting: "En attente",
        .discordApplication: "Application Discord",
        .applicationIDExplanation:
            "L’Application ID relie ta présence à l’application créée sur le portail Discord.",
        .save: "Enregistrer",
        .openDeveloperPortal: "Ouvrir le portail développeur ↗",
        .noDiscordTokenOrPasswordIsRequired: "Aucun token ni mot de passe Discord n’est demandé.",
        .xcodeAccess: "Accès à Xcode",
        .allowed: "Autorisé",
        .permissionNeeded: "À autoriser",
        .accessibilityExplanation:
            "macOS doit autoriser la lecture du nom du fichier actif. Xcode et Xcode Beta sont pris en charge.",
        .openMacOSPermissions: "Ouvrir les autorisations macOS",
        .permissionMigrationExplanation:
            "Si l’accès reste refusé après une mise à jour, retire l’ancienne entrée puis réajoute Xcode Presence depuis Applications.",
        .nothingShowingOnYourProfile: "Rien n’apparaît sur ton profil ?",
        .discordVisibilityExplanation:
            "Garde Discord pour Mac ouvert et vérifie que le partage d’activité est activé. Une confirmation indique que Discord a reçu l’activité ; sa visibilité dépend aussi des réglages de ton compte.",
        .checkNow: "Vérifier maintenant",
        .inYourMenuBarNAlwaysAClickAway: "Dans ta barre des menus.\nToujours à portée de clic.",
        .onYOURPROFILE: "SUR TON PROFIL",
        .whenTOSHARE: "QUAND PARTAGER",
        .pauseWhenInactive: "Pause après inactivité",
        .neverByDefaultPausingKeepsTheSessionTimer:
            "Jamais par défaut. Une pause conserve le compteur de session.",
        .inactivity: "Inactivité",
        .never: "Jamais",
        .sharingPrivacyExplanation:
            "Le code source et les chemins complets ne sont jamais partagés. Les changements sont enregistrés automatiquement.",
        .macosAccess: "Accès macOS",
        .lastFileRetained: "Dernier fichier conservé",
        .fileDetected: "Fichier détecté",
        .activityReceived: "Activité reçue",
        .confirmedByDiscordAt: "Confirmé par Discord à ",
        .updatesAutomaticallyEvery5Seconds: "Mise à jour automatique toutes les 5 secondes",
        .refresh: "Actualiser",
        .openConnection: "Ouvrir Connexion",
        .noActivityShared: "Aucune activité partagée",
        .yourNextFileWillAppearHere: "Ton prochain fichier apparaîtra ici.",
        .checking: "Vérification…",
        .letSConnectDiscord: "Connectons Discord",
        .waitingForXcode: "En attente de Xcode",
        .waitingForAFile: "En attente d’un fichier",
        .xcodeIsInTheBackground: "Xcode est en arrière-plan",
        .pausedDueToInactivity: "En pause pour inactivité",
        .sharingIsPaused: "Le partage est en pause",
        .connectingToDiscord: "Connexion à Discord",
        .checkYourConnection: "Vérifie ta connexion",
        .yourActivityIsBeingShared: "Ton activité est partagée",
        .designPreview: "Aperçu du design",
        .readingXcodeAndConnectingToDiscord: "Lecture de Xcode et connexion à Discord",
        .addYourApplicationIDInConnection: "Ajoute ton Application ID dans Connexion.",
        .allowXcodePresenceInMacOSPrivacySettings:
            "Autorise Xcode Presence dans les réglages de confidentialité macOS.",
        .openXcodeOrXcodeBetaToGetStarted: "Ouvre Xcode ou Xcode Beta pour commencer.",
        .missingDocumentExplanation:
            "Xcode est ouvert, mais aucun document enregistré n’a été détecté. Sélectionne un fichier source.",
        .foregroundOnlyExplanation:
            "Tes réglages autorisent le partage seulement quand Xcode est au premier plan.",
        .resumeSharingWheneverYouLike: "Reprends le partage quand tu le souhaites.",
        .retainedFileExplanation:
            "Le dernier fichier reste partagé dans les autres panneaux Xcode. Sélectionne un autre fichier pour actualiser ta présence.",
        .discordConfirmedReceiptOfThisActivity: "Discord a confirmé la réception de cette activité.",
        .sampleDataNoActivityIsSentToDiscord: "Données d’exemple. Aucune activité n’est envoyée à Discord.",
        .undo: "Annuler",
        .cut: "Couper",
        .copy: "Copier",
        .paste: "Coller",
        .selectAll: "Tout sélectionner",
        .inactivityExplanation:
            "Aucune entrée clavier ou souris depuis %d minutes. Modifie ce délai dans Partage.",
        .fileName: "Nom du fichier",
        .fileNameExample: "Par exemple : ContentView.swift",
        .projectName: "Nom du projet",
        .theProjectOrPackageContainingTheFile: "Le projet ou package auquel appartient le fichier",
        .languageAndIcon: "Langage et icône",
        .theIconAutomaticallyMatchesTheFileType: "L’icône s’adapte automatiquement au type de fichier",
        .sessionDuration: "Durée de session",
        .sessionDurationExplanation:
            "Le temps depuis le début de la session Xcode, pauses comprises",
        .onlyWhenXcodeIsInTheForeground: "Seulement quand Xcode est au premier plan",
        .otherwiseSharingContinuesInTheBackground: "Sinon, le partage continue en arrière-plan",
        .yourActivity: "Ton activité",
        .sharing: "Partage",
        .connection: "Connexion",
        .settingsLabel: "Réglages",
    ]
}
