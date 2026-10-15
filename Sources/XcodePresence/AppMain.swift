import AppKit
import PresenceCore
import SwiftUI

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = PresenceModel()
    private var statusItem: NSStatusItem!
    private var window: NSWindow?
    private var terminating = false
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        installApplicationMenu()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let path = Bundle.main.path(forResource: "MenuBarTemplate", ofType: "png"),
            let icon = NSImage(contentsOfFile: path)
        {
            icon.size = NSSize(width: 18, height: 18)
            icon.isTemplate = true
            statusItem.button?.image = icon
        } else {
            statusItem.button?.image = NSImage(
                systemSymbolName: "chevron.left.forwardslash.chevron.right",
                accessibilityDescription: "Xcode Presence")
        }
        statusItem.button?.toolTip = "Xcode Presence"
        model.onMenuChange = { [weak self] in self?.updateMenu() }
        model.start()
        updateMenu()
        if model.preview || !DiscordIPC.validClientID(model.clientID)
            || ProcessInfo.processInfo.arguments.contains("--show-settings")
        {
            showWindow()
        }
    }
    private func installApplicationMenu() {
        let menu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu(title: "Xcode Presence")
        appMenu.addItem(withTitle: "About Xcode Presence", action: #selector(about), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        appMenu.addItem(
            withTitle: "Hide Xcode Presence", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(.separator())
        appMenu.addItem(
            withTitle: "Quit Xcode Presence", action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q")
        appItem.submenu = appMenu
        menu.addItem(appItem)
        let editItem = NSMenuItem()
        let edit = NSMenu(title: "Edit")
        for (title, action, key) in [
            ("Undo", "undo:", "z"), ("Cut", "cut:", "x"), ("Copy", "copy:", "c"), ("Paste", "paste:", "v"),
            ("Select All", "selectAll:", "a"),
        ] {
            edit.addItem(withTitle: title, action: Selector(action), keyEquivalent: key)
        }
        editItem.submenu = edit
        menu.addItem(editItem)
        NSApp.mainMenu = menu
        for item in appMenu.items
        where item.action == #selector(about) || item.action == #selector(showSettings) { item.target = self }
    }
    func updateMenu() {
        guard statusItem != nil else { return }
        let menu = NSMenu()
        menu.addItem(withTitle: model.title, action: nil, keyEquivalent: "")
        if let file = model.file { menu.addItem(withTitle: file.name, action: nil, keyEquivalent: "") }
        menu.addItem(.separator())
        add(menu, model.text(.openSettings), #selector(showWindow))
        add(menu, model.text(.checkConnection), #selector(check))
        add(menu, model.text(.reconnectToDiscord), #selector(reconnect))
        add(
            menu, model.paused ? model.text(.resumeSharing) : model.text(.pauseSharing),
            #selector(togglePause))
        menu.addItem(.separator())
        add(menu, model.text(.gettingStarted), #selector(guide))
        add(menu, model.text(.quitXcodePresence), #selector(quit), key: "q")
        statusItem.menu = menu
        statusItem.button?.toolTip = "Xcode Presence — " + model.title
        if let appMenu = NSApp.mainMenu?.items.first?.submenu {
            appMenu.items.first?.title = model.text(.aboutXcodePresence)
            appMenu.items.first(where: { $0.action == #selector(showSettings) })?.title = model.text(
                .settings)
            appMenu.items.first(where: { $0.action == #selector(NSApplication.hide(_:)) })?.title =
                model.text(.hideXcodePresence)
            appMenu.items.last?.title = model.text(.quitXcodePresence)
        }
        if let edit = NSApp.mainMenu?.items.last?.submenu {
            edit.title = model.text(.edit)
            for (index, key) in [AppText.undo, .cut, .copy, .paste, .selectAll].enumerated() {
                edit.items[index].title = model.text(key)
            }
        }
    }
    private func add(_ menu: NSMenu, _ title: String, _ action: Selector, key: String = "") {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        menu.addItem(item)
    }
    @objc func showWindow() {
        if window == nil {
            let view = NSHostingView(rootView: PresenceView(model: model))
            let newWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 920, height: 680),
                styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false
            )
            newWindow.title = model.preview ? "Xcode Presence — Preview" : "Xcode Presence"
            newWindow.contentView = view
            newWindow.contentMinSize = NSSize(width: 840, height: 660)
            newWindow.isReleasedWhenClosed = false
            newWindow.center()
            window = newWindow
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
    @objc func showSettings() {
        model.page = .settings
        showWindow()
    }
    @objc func check() { model.refresh(force: true) }
    @objc func reconnect() { model.reconnect() }
    @objc func togglePause() { model.paused.toggle() }
    @objc func guide() {
        if let url = Bundle.main.url(forResource: "Guide", withExtension: "html") {
            NSWorkspace.shared.open(url)
        }
    }
    @objc func quit() { NSApp.terminate(nil) }
    @objc func about() {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "Xcode Presence", .applicationVersion: AppMetadata.version,
            .credits: NSAttributedString(
                string: model.text(.aboutReconstruction)),
        ])
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showWindow()
        return true
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if terminating { return .terminateNow }
        terminating = true
        model.terminate { sender.reply(toApplicationShouldTerminate: true) }
        return .terminateLater
    }
}

@main enum Main {
    @MainActor static func main() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--diagnose") {
            let reading = XcodeMonitor.read(app: XcodeMonitor.runningApp(preferredPID: nil))
            let object: [String: Any] = [
                "accessibilityAllowed": reading.trusted, "xcodeRunning": reading.pid != nil,
                "editor": reading.editor, "file": reading.file?.name as Any? ?? NSNull(),
                "project": reading.file?.project as Any? ?? NSNull(),
                "socketCandidates": DiscordIPC.socketPaths.count,
            ]
            if let data = try? JSONSerialization.data(
                withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
                let text = String(data: data, encoding: .utf8)
            {
                print(text)
            }
            return
        }
        if args.contains("--ipc-check") {
            do {
                let client = DiscordIPC()
                let id = UserDefaults.standard.string(forKey: "clientID") ?? ""
                try client.connect(clientID: id)
                _ = try client.setActivity(nil)
                print("Discord READY + SET_ACTIVITY acknowledgement verified (no activity published).")
                client.disconnect()
            } catch {
                fputs("\(error.localizedDescription)\n", stderr)
                exit(1)
            }
            return
        }
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.run()
        withExtendedLifetime(delegate) {}
    }
}
