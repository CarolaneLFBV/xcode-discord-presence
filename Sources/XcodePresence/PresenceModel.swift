import AppKit
import Combine
import CoreGraphics
import PresenceCore

enum SettingsPage: Int, CaseIterable { case activity, sharing, connection, settings }

@MainActor final class PresenceModel: ObservableObject {
    private let preferenceStore: PreferenceStore
    private let worker = DispatchQueue(label: "XcodePresence.monitor", qos: .utility)
    private let publisher = PresencePublisher()
    private var session = EditorSession()
    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []
    private var busy = false
    private var pending = false
    private var generation = 0
    private var terminating = false
    private var lastSignature: Data?
    private var lastSent: Date?
    let preview: Bool
    var onMenuChange: (() -> Void)?

    @Published var page: SettingsPage = .activity
    @Published private var preferences: Preferences {
        didSet { preferencesDidChange() }
    }
    var language: AppLanguage {
        get { preferences.language }
        set { preferences.language = newValue }
    }
    var showFile: Bool {
        get { preferences.showFile }
        set { preferences.showFile = newValue }
    }
    var showProject: Bool {
        get { preferences.showProject }
        set { preferences.showProject = newValue }
    }
    var showLanguage: Bool {
        get { preferences.showLanguage }
        set { preferences.showLanguage = newValue }
    }
    var showElapsed: Bool {
        get { preferences.showElapsed }
        set { preferences.showElapsed = newValue }
    }
    var focusOnly: Bool {
        get { preferences.focusOnly }
        set { preferences.focusOnly = newValue }
    }
    var idleMinutes: Int {
        get { preferences.idleMinutes }
        set { preferences.idleMinutes = newValue }
    }
    var paused: Bool {
        get { preferences.paused }
        set { preferences.paused = newValue }
    }
    var clientID: String {
        get { preferences.clientID }
        set { preferences.clientID = newValue }
    }
    @Published var clientIDDraft: String
    @Published var saveMessage = ""
    @Published var saveFailed = false
    @Published private(set) var phase: PresencePhase = .checking
    @Published private(set) var editor = "Xcode"
    @Published private(set) var file: EditorFile?
    @Published private(set) var retainingFile = false
    @Published private(set) var xcodeRunning = false
    @Published private(set) var trusted = false
    @Published private(set) var discordRunning = false
    @Published private(set) var lastConfirmed: Date?
    @Published private(set) var lastChecked: Date?
    @Published private(set) var connectionError = ""
    @Published private(set) var sessionStart: Date?

    init(
        preview: Bool = ProcessInfo.processInfo.environment["XCODE_PRESENCE_PREVIEW"] == "1"
            || Bundle.main.bundleIdentifier?.hasSuffix(".preview") == true,
        defaults: UserDefaults? = nil
    ) {
        self.preview = preview
        let selectedDefaults =
            defaults
            ?? (preview
                ? UserDefaults(suiteName: "local.xcodepresence.preview") ?? .standard
                : .standard)
        let store = PreferenceStore(defaults: selectedDefaults)
        let loaded = store.load()
        preferenceStore = store
        preferences = loaded
        clientIDDraft = loaded.clientID
    }

    func text(_ key: AppText) -> String {
        AppLocalizer(language: language).text(key)
    }

    private func preferencesDidChange() {
        preferenceStore.save(preferences)
        generation += 1
        publisher.invalidate()
        onMenuChange?()
        refresh(force: true)
    }

    func saveClientID() {
        let id = clientIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard DiscordIPC.validClientID(id) else {
            saveFailed = true
            saveMessage = text(.invalidApplicationIDExplanation)
            return
        }
        clientID = id
        clientIDDraft = id
        saveFailed = false
        saveMessage = text(.applicationIDSaved)
    }
    var options: SharingOptions {
        var result = SharingOptions()
        result.file = showFile
        result.project = showProject
        result.language = showLanguage
        result.elapsed = showElapsed
        return result
    }
    var activity: ActivityPresentation? {
        file.map {
            ActivityPresentation(
                editor: editor, file: $0, options: options, language: language, start: sessionStart)
        }
    }
    func start() {
        refresh(force: true)
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        let center = NSWorkspace.shared.notificationCenter
        for name in [
            NSWorkspace.didActivateApplicationNotification, NSWorkspace.didTerminateApplicationNotification,
            NSWorkspace.didLaunchApplicationNotification, NSWorkspace.didWakeNotification,
            NSWorkspace.screensDidWakeNotification,
        ] {
            observers.append(
                center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                    Task { @MainActor in self?.refresh() }
                })
        }
    }
    func refresh(force: Bool = false) {
        guard !terminating else { return }
        if preview {
            editor = "Xcode Beta 27.2"
            file = EditorFile(
                url: URL(fileURLWithPath: "/Preview/ExampleProject/ContentView.swift"),
                project: "ExampleProject")
            if sessionStart == nil { sessionStart = Date().addingTimeInterval(-134) }
            xcodeRunning = true
            trusted = true
            discordRunning = true
            phase = paused ? .paused : .preview
            onMenuChange?()
            return
        }
        if busy {
            pending = true
            return
        }
        busy = true
        let revision = generation
        let runningApp = XcodeMonitor.runningApp(preferredPID: session.pid)
        discordRunning = NSWorkspace.shared.runningApplications.contains {
            ($0.bundleIdentifier ?? "").hasPrefix("com.hnc.Discord")
        }
        let idle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .null)
        worker.async { [weak self] in
            let reading = XcodeMonitor.read(app: runningApp)
            DispatchQueue.main.async { self?.consume(reading, idle: idle, revision: revision, force: force) }
        }
    }
    private func consume(_ reading: XcodeReading, idle: TimeInterval, revision: Int, force: Bool) {
        guard !terminating else {
            busy = false
            return
        }
        if revision != generation {
            busy = false
            refresh(force: true)
            return
        }
        lastChecked = Date()
        trusted = reading.trusted
        xcodeRunning = reading.pid != nil
        editor = reading.editor
        session.update(pid: reading.pid, file: reading.file)
        // Revoking permission must never republish a retained file.
        file = trusted ? session.file : nil
        retainingFile = trusted && session.retainingFile
        sessionStart = session.start
        let next = SharingPolicy.phase(
            paused: paused, validID: DiscordIPC.validClientID(clientID),
            trusted: trusted, running: xcodeRunning, focusOnly: focusOnly,
            foreground: reading.foreground, idleMinutes: idleMinutes,
            idleSeconds: idle, hasFile: file != nil)
        let desired = next == .connecting ? activity?.payload : nil
        let signature =
            desired.flatMap { try? JSONSerialization.data(withJSONObject: $0, options: .sortedKeys) }
            ?? Data("null".utf8)
        phase =
            next == .connecting && lastSignature == signature && lastConfirmed != nil
                && connectionError.isEmpty ? .live : next
        onMenuChange?()
        let id = clientID
        let shouldSend =
            force || signature != lastSignature || Date().timeIntervalSince(lastSent ?? .distantPast) >= 4
        guard shouldSend else {
            busy = false
            finishPending()
            return
        }
        publisher.publish(clientID: id, activityJSON: desired == nil ? nil : signature) {
            [weak self] outcome in
            DispatchQueue.main.async {
                guard let self else { return }
                self.busy = false
                guard revision == self.generation, !self.terminating else {
                    self.refresh(force: true)
                    return
                }
                switch outcome {
                case .confirmed(let date):
                    self.connectionError = ""
                    self.lastConfirmed = date
                    self.lastSignature = signature
                    self.lastSent = Date()
                    self.phase = .live
                case .cleared:
                    self.connectionError = ""
                    self.lastSignature = signature
                    self.lastSent = Date()
                case .failed(let message):
                    self.connectionError = message
                    if desired != nil { self.phase = .failed }
                case .cancelled:
                    break
                }
                self.onMenuChange?()
                self.finishPending()
            }
        }
    }
    private func finishPending() {
        if pending {
            pending = false
            refresh(force: true)
        }
    }
    func reconnect() {
        generation += 1
        lastSignature = nil
        lastConfirmed = nil
        connectionError = ""
        publisher.reset()
        refresh(force: true)
    }
    func terminate(completion: @escaping @MainActor @Sendable () -> Void) {
        terminating = true
        generation += 1
        timer?.invalidate()
        let center = NSWorkspace.shared.notificationCenter
        observers.forEach(center.removeObserver)
        publisher.shutdown {
            DispatchQueue.main.async { completion() }
        }
    }
    func openPermissions() {
        NSWorkspace.shared.open(
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
    var title: String { statusText.title }
    var subtitle: String { statusText.subtitle }
    private var statusText: PresenceStatusText {
        PresenceStatusText(
            phase: phase, language: language, retainingFile: retainingFile,
            idleMinutes: idleMinutes, connectionError: connectionError)
    }
}
