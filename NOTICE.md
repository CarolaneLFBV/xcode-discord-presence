# Artwork and third-party notices

The project source code is MIT licensed. That license does not relicense third-party artwork or grant trademark rights.

| Resource | Origin | Status |
| --- | --- | --- |
| Language badges in `Resources/LanguageIcons` | [GitHub Explore, pinned revision](https://github.com/github/explore/tree/4a3fe88f59d2a20ea3a1a12b4bbf8cf1f1d34670/topics) | Unmodified PNGs, CC-BY-4.0; attribution and full upstream license are bundled in `Resources/ThirdPartyNotices.txt`. |
| Xcode icon shown in the app | The user's installed Xcode application | Resolved locally through AppKit. No standalone Apple icon asset is bundled. |
| Xcode icon shown by Discord | Public image URL hosted by Apple | Referenced by URL, not copied into the repository or application bundle. |
| `PresenceApp.icns`, `MenuBarTemplate.png` | Existing Xcode Presence project artwork | Preserved from the maintainer's original application to retain its appearance. These are not official Apple or Discord app icons. |
| `docs/images/activity-example.svg` | Original project illustration | MIT licensed, with generic sample data and a generic code icon; not a screenshot or an official product icon. |

Content based on [github.com/github/explore](https://github.com/github/explore) used under the [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/) license. No modifications were made to the included language logos.

Xcode, Swift and macOS are trademarks of Apple Inc. Discord and the language logos are trademarks of their respective owners. This is an independent utility, not affiliated with, endorsed by or sponsored by Apple, Discord or GitHub.

Keep these notices with redistributed builds. The build script includes `ThirdPartyNotices.txt` in the app bundle. The [Apple trademark guidelines](https://www.apple.com/legal/intellectual-property/guidelinesfor3rdparties.html) and upstream logo owners' policies remain separate from the code license.
