# Xcode Presence

A small native macOS menu bar app that shares your Xcode activity on Discord: the current file, project, programming language and session duration.

[MIT license](LICENSE) · [Artwork notices](NOTICE.md)

<p align="center">
  <img src="docs/images/discord-presence.png" alt="Discord profile showing Xcode Beta 27.2, the current Swift file, project and session duration" width="340">
</p>

## Features

- Supports Xcode and Xcode Beta; the title follows the running application's product version.
- Shows the active saved file, project or Swift package, language badge and elapsed session time.
- Keeps the last detected file while you use Coding Assistant or another documentless panel.
- Lets you hide the file, project, language or timer independently.
- Manual pause, optional foreground-only sharing, and inactivity timeouts of 5, 15 or 30 minutes.
- French, English and automatic macOS language selection.
- Runs in the menu bar without a Dock icon. Closing its settings window keeps it running.
- Connects locally to Discord. No Discord account token, password or bot is required.

## Download the app

[Download Xcode Presence 0.3.1 for macOS](https://github.com/CarolaneLFBV/xcode-discord-presence/releases/download/v0.3.1/XcodePresence-0.3.1-universal.dmg) — universal Apple Silicon + Intel DMG, signed with Developer ID and notarized by Apple.

Open the DMG, drag **Xcode Presence** into **Applications**, and launch it. No compilation is needed. Then follow [Connect Discord](#connect-discord) to set the public Application ID and grant macOS Accessibility permission. The release includes `SHA256SUMS.txt` to verify the downloaded file.

## Requirements

- macOS 13 or later.
- Xcode installed, and the Discord desktop app running on the same Mac.
- To build from source: Xcode 15 / Swift 5.9 or later.

The downloadable DMG includes Apple Silicon and Intel slices. Local development builds target the architecture of the Mac used to compile them. [GitHub Actions](https://github.com/CarolaneLFBV/xcode-discord-presence/actions) checks tests, packaging and signatures on Intel and Apple Silicon. macOS 13 is the deployment target; runtime behavior on the minimum supported OS has not been verified.

## Install from source

Download or clone this repository, then open Terminal in its root folder:

```sh
./scripts/test.sh
./scripts/build.sh
open dist
```

The build creates `dist/Xcode Presence.app` and `dist/Xcode Presence.zip`. Quit any running copy, then move the app into **Applications** and open it. Keep one installed copy to avoid duplicate presences and ambiguous macOS permissions.

This development build is signed locally and is not notarized. Use the signed and notarized DMG above for installation without compiling.

If your source folder is synced by a file provider, use the generated ZIP to move the app into Applications. The build signs a temporary bundle and archives it without Finder metadata that could interfere with signature validation.

You can also open `Package.swift` in Xcode to browse and edit the sources. Use the build script to assemble the complete application bundle and its icons and guide.

## Connect Discord

1. Open the [Discord Developer Portal](https://discord.com/developers/applications) and create an application. A name such as **Xcode** works well.
2. Copy its **Application ID** from General Information. This is a public numeric identifier, not a token.
3. Open Xcode Presence from its menu bar icon. In **Connection**, paste the ID and click **Save**.
4. Choose **Open macOS permissions**, then allow the installed Xcode Presence app in **Privacy & Security → Accessibility**. Some macOS beta versions call this page **Device Control and Data Access**.
5. Keep Discord for Mac open with activity sharing enabled, then select a saved file in Xcode.

The Activity page shows whether macOS access is allowed, a file is detected and Discord has confirmed receipt. Profile visibility also depends on your Discord account's activity-sharing settings.

After replacing a locally signed build, macOS may require you to remove only the old Xcode Presence entry and add the copy in Applications again. The app never grants itself that permission.

## Sharing and privacy

All display fields are enabled initially. Sharing continues in the background, with inactivity pausing disabled by default. Change these preferences in **Sharing**. Pauses and reconnects preserve the start of the Xcode session.

Only enabled display fields are sent to the local Discord client. Source code and full file paths are not included in the activity payload. The app reads document metadata through macOS Accessibility; it does not read the source editor's text value. Discord may fetch language artwork from GitHub and the Xcode artwork URL from Apple.

Changing privacy settings cancels queued requests and requests still waiting for Discord's connection handshake. A frame already delivered to Discord cannot be recalled; the next clear or update follows the bounded in-flight operation.

## Development

```sh
# Render the same interface with generic sample data and separate preferences.
# This preview never connects to Discord.
./scripts/build.sh --preview
open "dist/Xcode Presence Preview.app"

# Format Swift files, then verify formatting (swift-format required).
./scripts/format.sh
./scripts/format.sh --check
```

There are no third-party Swift package dependencies. `PresenceCore` contains the display models, sharing rules and Discord transport. `XcodePresence` contains the macOS integration, preferences, localization and SwiftUI screens.

Before contributing, run `./scripts/test.sh`, `./scripts/build.sh` and the formatting check. Preserve existing preference keys and keep credentials, signing material and diagnostic logs out of commits. `./scripts/backup-sources.sh` creates a local source archive outside the project; it does not publish or upload anything.

`./scripts/export-public.sh` exports the committed public tree to a ZIP without `.git` history, ignored files or build products. It requires a clean working tree. This is useful when a local project's earlier commits contained private examples or assets that are no longer distributed. Import that export into a fresh repository when preparing an initial public release; no script creates a remote or pushes anything.

### Signed releases

Maintainers need a valid Developer ID Application identity in their Keychain. Prepare the universal DMG, configure a local notarization profile interactively, then notarize it:

```sh
./scripts/release.sh prepare
xcrun notarytool store-credentials PROFILE_NAME
./scripts/release.sh notarize PROFILE_NAME
```

Only publish the final notarized DMG and `SHA256SUMS.txt` from `dist/distribution/`. The `-pending-notarization.dmg` and submission JSON are local intermediate files. Credentials and private keys stay in the Keychain. The signing certificate identifies the Apple Developer account. `PRESENCE_SIGNING_IDENTITY`, `PRESENCE_RELEASE_OUTPUT` and `PRESENCE_RELEASE_SCRATCH` can override the signing identity, output folder and build cache.

## Troubleshooting

- **No file detected:** allow Accessibility access, then select a saved source file. Some Xcode panels do not expose a document; the last detected file is retained until another is selected or that Xcode process exits.
- **Discord not found:** open the desktop app. A browser-only Discord session does not expose the required local IPC socket.
- **Activity received but not visible:** check Discord's account and per-server activity-sharing preferences.
- **No language badge:** unknown file types may have a label without an icon. The activity's main icon still identifies Xcode.
- **Xcode Beta 27.2:** `27.2` is the product version, not a beta sequence number.

For local metadata diagnostics, run:

```sh
"dist/Xcode Presence.app/Contents/MacOS/XcodePresence" --diagnose
"dist/Xcode Presence.app/Contents/MacOS/XcodePresence" --ipc-check
```

The first prints permission and document metadata, which you should review before sharing a log. The second verifies Discord's handshake and a clear-command acknowledgement without publishing sample activity. Command-line execution may have a different macOS permission context from a normally launched app.

## License and artwork

Source code is available under the [MIT license](LICENSE). Language logos retain their upstream CC-BY-4.0 license and attribution. The app obtains its Xcode icon from an installed copy of Xcode rather than bundling an Apple bitmap. See [NOTICE.md](NOTICE.md) and the bundled [third-party notices](Resources/ThirdPartyNotices.txt).

The screenshot above was supplied by the maintainer for this README. This project is an independent utility and is not affiliated with or endorsed by Apple, Discord or GitHub.
