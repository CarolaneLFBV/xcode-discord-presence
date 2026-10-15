# Signed macOS releases

Public downloads use a Developer ID Application signature, Hardened Runtime, a secure signing timestamp, Apple notarization and a stapled ticket. The existing development build script continues to produce a locally signed build for contributors.

## Prepare a universal DMG

On a Mac with Xcode and a valid **Developer ID Application** identity and private key in the Keychain:

```sh
./scripts/test.sh
./scripts/release.sh prepare
```

The script uses the only valid Developer ID identity it finds, or the SHA-1 in `PRESENCE_SIGNING_IDENTITY` when explicitly set. It compiles both arm64 and x86_64, assembles a universal binary, strips debug information, signs the app, and creates a signed DMG containing an Applications shortcut. It never exports the private key. The installed app and its Accessibility permission are not changed.

The output ending in `-pending-notarization.dmg` is for validation only. **Do not publish that file.** A signature alone does not complete the public release process. The signing certificate exposes the identity of the Apple Developer account; it is not an anonymous signature.

## Authorize Apple's notary service once

Run this yourself in an interactive Terminal:

```sh
xcrun notarytool store-credentials PROFILE_NAME
```

Choose a local profile name, then enter your Apple ID, Team ID and app-specific password at the prompts from Apple's tool. Generate an app-specific password yourself at [account.apple.com](https://account.apple.com/) if needed. The credentials are validated by Apple and saved in your local Keychain, not in the repository or a plaintext file. Do not paste a password, API private key or certificate export into an issue or chat. An existing `notarytool` Keychain profile can be used instead.

## Notarize and verify

```sh
./scripts/release.sh notarize PROFILE_NAME
```

The DMG is sent to Apple's notary service. Only an `Accepted` result followed by successful stapling, signature and Gatekeeper checks produces the final `XcodePresence-VERSION-universal.dmg` and `SHA256SUMS.txt`. The local submission JSON is diagnostic material, not a release asset.

The default output folder is `dist/distribution/`, which Git ignores. `PRESENCE_RELEASE_OUTPUT` overrides that folder and `PRESENCE_RELEASE_SCRATCH` selects a reusable build cache. Keep both outside tracked source folders when using overrides. Signing material, credentials, logs and build products must stay out of commits.

## Publish the finished artifact

Upload only the final notarized DMG and its checksum file to a versioned GitHub Release. Link the website's download button to that real release once it exists. Do not use the ad hoc ZIP from `scripts/build.sh` for public downloads.

Users download the DMG and drag the app into Applications; they do not need to compile it. They still need Xcode, the Discord desktop client, their Discord Application ID and manual macOS Accessibility permission. Apple Silicon and Intel slices are included, but a successful build is not a substitute for runtime testing on both architectures and the minimum supported macOS version.

References: [Apple notarization](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution), [Developer ID distribution](https://help.apple.com/xcode/mac/current/en.lproj/dev033e997ca.html).
