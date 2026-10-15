# Contributing

## Local setup

Use a Mac with Xcode installed. Open `Package.swift` to navigate the code; use the scripts to test and assemble the complete menu bar app:

```sh
./scripts/test.sh
./scripts/build.sh --preview
open "dist/Xcode Presence Preview.app"
```

The preview has its own bundle identifier and preferences, uses generic examples and does not connect to Discord. Use it for visual changes. Avoid running two production copies at the same time.

## Checks before submitting a change

Run `./scripts/test.sh` and `./scripts/build.sh`. If you have the Swift toolchain's `swift-format`, run `./scripts/format.sh --check`; run it without `--check` to apply the checked-in formatting configuration. `SWIFT_FORMAT` can point to a formatter executable explicitly. Formatting does not add a Swift package dependency.

Keep changes focused. Add regression tests for behavior changes, especially privacy, stale requests, file retention and RPC handling. Do not add tests that only repeat view layout or implementation details. When changing the UI, compare all four pages in French and English, at the minimum window size and in a larger window. Keep the current visual design and preference defaults unless the change explicitly requests otherwise.

The GitHub workflow runs tests and packages the app on stable Xcode/macOS combinations, including Apple Silicon and Intel. It uses read-only repository permissions and has no deployment, release-upload or publishing step. Its hosted runs are pending until a repository exists.

## Manual integration checks

For a change affecting Xcode or Discord integration, build the production app, quit the previous copy and install the new one in Applications. Configure your own Discord Application ID and grant Accessibility access manually. Check file changes, last-file retention, pause/resume, foreground-only behavior and reconnecting Discord. A new local signature may require reauthorizing the installed copy.

Source edits and tests do not require replacing a maintainer's working application. Keep generated builds, local preferences, DerivedData, signing material and diagnostic logs out of commits. The Application ID is public but examples should still use a synthetic numeric value.

## Project conventions

- `PresenceCore` has no dependency on SwiftUI or AppKit.
- Views compose UI; the model coordinates state; preferences and user-facing text have separate files.
- Preserve UserDefaults keys to keep existing installations compatible.
- Never read or publish the source editor's text value or include full paths in activity payloads.
- Keep third-party artwork notices with the bundle. Do not add Apple icon assets to the repository; obtain the local Xcode icon through AppKit.
- The MIT license applies to contributed code. Third-party artwork retains its own license and trademark status.

## Reporting issues and proposing changes

Include the macOS, Xcode, Discord and Xcode Presence versions, steps to reproduce, expected behavior and the Activity page's diagnostic status. Review any diagnostic output or screenshots before posting: metadata may include your project and file names. Do not include account tokens, passwords or source code unrelated to the issue.

Explain pull requests in terms of the problem and resulting behavior, then list the checks actually run. If a platform or manual integration path was not tested, say so rather than implying full compatibility.
