# Changelog

## 0.3.1 — 2026-10-15

- Preserve the menu bar icon's aspect ratio and let its status item fit the image width.
- Provide a universal Apple Silicon + Intel DMG, Developer ID signed, notarized by Apple and stapled for distribution.
- Add repeatable signing/notarization scripts; credentials and private keys stay in the local Keychain.

- Organize the SwiftUI screens, preferences, localization and core models into focused files.
- Prevent obsolete queued or still-connecting Discord requests from publishing after privacy settings change.
- Add tests for publication cancellation, retries, preference compatibility and localization completeness.
- Bound Accessibility traversal by time as well as node count and depth.
- Read the Xcode icon from an installed application instead of bundling an Apple bitmap.
- Add MIT licensing for code, explicit artwork notices, contributor documentation and a build/test workflow.
- Use generic preview examples and provide English/French installation guides.

The design, sharing controls, existing preference keys and supported menu bar workflow are preserved.
