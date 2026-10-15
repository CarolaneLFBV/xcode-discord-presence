# Validation

This document records completed checks, not a guarantee that every supported OS or Xcode version has been exercised.

## Local environment

- Apple Silicon Mac, macOS 27.2.
- Stable Xcode 27.1 and Xcode 27.2 beta 3 are installed.
- Deployment target: macOS 13. The minimum OS and Intel runtime have not been tested locally.

## Open-source preparation

Completed locally on 2026-10-15 with stable Xcode 27.1:

- 23 XCTest tests passed: 17 in PresenceCoreTests and 6 in XcodePresenceTests.
- Debug test build and Release application/preview builds succeeded.
- Strict swift-format lint passed; shell syntax and local documentation links were checked.
- Strict codesign validation passed on the application and preview extracted from their generated ZIPs.
- The four preview screens were checked in French and English. File-name sharing updates the activity card, changing language updates the UI immediately, and pause/resume preserves the session start. Layout, artwork and navigation were visually reviewed.

The new tests cover preference compatibility/persistence, translations, observable settings, publication failures, reconnecting after an Application ID change and invalidating a pending publication during connection. Preview runs use generic samples and a separate preference suite; they do not connect to Discord. The installed working application was not replaced during this cleanup.

The new CI workflow is configuration only until the repository is published. It must not be described as having passed a hosted GitHub run.

## Previous manual integration baseline

Before this cleanup, version 0.3.0 was installed and manually authorized by the user. It detected a real Xcode project and file, switched to a Swift source file with the Swift badge, and received SET_ACTIVITY acknowledgements from the local Discord client. Pause/resume preserved the session timer. Opening Coding Assistant kept the activity present. The previous document and project navigator were restored after testing.

The genuinely documentless-panel case is covered by the session tests; the observed Coding Assistant layout still exposed an editor document. Public profile visibility from another Discord account was not checked.

## Manual checks for future changes

Verify file changes, retention when a panel has no document, pause/resume, foreground-only sharing, inactivity, reconnecting Discord and a new Application ID. Compare the four screens in English/French and check the preview never connects to Discord. Only a person can grant or change macOS Accessibility permissions.
