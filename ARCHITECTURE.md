# Architecture

This is a Swift package with two production targets and no package dependencies.

## Source layout

```text
Sources/
  PresenceCore/
    Activity.swift          Display-only Discord payload construction
    AppLanguage.swift       Supported language selection
    CodeLanguage.swift      File-extension and badge mapping
    DiscordIPC.swift        Unix socket framing and Discord RPC
    EditorSession.swift     Last-file retention and session start
    PresencePublisher.swift Serial transport ownership and cancellation
    SharingOptions.swift    Per-field privacy options
    SharingPolicy.swift     Pause/foreground/inactivity decisions
    XcodeVersion.swift      Product-version display name
  XcodePresence/
    AppMain.swift           Application lifecycle and menu bar
    AppMetadata.swift       Bundle version
    Preferences.swift       Stable UserDefaults keys and defaults
    PresenceModel.swift     Observable UI state and orchestration
    XcodeMonitor.swift      Accessibility metadata and project detection
    Localization/          Typed English/French strings and status text
    Views/                 Activity, Sharing, Connection and Settings screens
```

`PresenceView` composes the same sidebar, page header and cards as the original application. The screen extraction preserves their modifiers, dimensions and colors; a small navigation spacing adjustment prevents the selected English label from being truncated. Shared visual helpers live in `ViewComponents`.

## Flow and ownership

The main-actor `PresenceModel` observes preferences and workspace changes, samples input inactivity and polls every five seconds. Its monitor queue reads Xcode document metadata away from the interface thread. Accessibility traversal is constrained by depth, node count and a time budget; per-call AX messaging has its own timeout. An unresponsive target can therefore overshoot the traversal budget by a bounded AX call rather than blocking the UI.

`EditorSession` keeps the last saved file if a panel exposes no document. Selecting another Xcode process or observing no running Xcode clears that state. `SharingPolicy` decides whether to publish. `ActivityPresentation` whitelists display fields and never serializes the file URL or editor text.

`PresencePublisher` owns a synchronous `DiscordTransport` on one serial queue. Its revision counter is protected by an `NSLock`, allowing main-thread preference changes to invalidate queued or still-connecting work immediately. The revision is checked before connection, after the READY handshake and before reporting confirmation. Newer requests supersede queued older ones. An activity already delivered to Discord cannot be recalled; the next clear/update waits for the bounded in-flight request to finish.

Changing Application ID clears the old client's activity before switching connections. Shutdown invalidates pending work, clears an established activity and disconnects. A failure disconnects the transport so the next poll starts a fresh handshake. All IPC reads and writes have deadlines, handle partial frames and ping/pong, and reject oversized frames.

The publisher is the only `@unchecked Sendable` type. That boundary is explicit: transport state belongs to its queue, while revision state uses the lock. Callers must not retain and independently use an injected transport. RPC JSON is encoded as `Data` before crossing queues, then decoded on the transport queue.

## Tests

Core tests cover field omission, session retention/reset, sharing policy, version labels, client IDs, framing, ping/pong, malformed/oversized replies and RPC errors. Publisher tests inject a recording transport with controlled handshakes to reproduce pause/privacy changes during connection, stale requests, retries, client ID changes and shutdown. App tests use isolated UserDefaults suites and check localization completeness. They do not require Discord, Xcode UI access or Accessibility permission.

Actual Accessibility behavior, Discord profile visibility, the rendered interface and permission migration still need manual checks. See [VALIDATION.md](VALIDATION.md).
