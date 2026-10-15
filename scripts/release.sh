#!/bin/bash
# Public macOS distribution. Credentials and private keys remain in the Keychain.
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="${PRESENCE_RELEASE_OUTPUT:-$PROJECT_DIR/dist/distribution}"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PROJECT_DIR/Info.plist")"
BASE_NAME="XcodePresence-$VERSION-universal"
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"
PENDING_DMG="$OUTPUT_DIR/$BASE_NAME-pending-notarization.dmg"
FINAL_DMG="$OUTPUT_DIR/$BASE_NAME.dmg"

case "${1:-prepare}" in
  prepare)
    IDENTITY="${PRESENCE_SIGNING_IDENTITY:-}"
    if [[ -z "$IDENTITY" ]]; then
      IDENTITIES="$(security find-identity -v -p codesigning | awk '/"Developer ID Application:/ {print $2}')"
      COUNT="$(printf '%s\n' "$IDENTITIES" | awk 'NF {n++} END {print n+0}')"
      if [[ "$COUNT" != 1 ]]; then
        printf 'Set PRESENCE_SIGNING_IDENTITY to a valid Developer ID Application certificate SHA-1.\n' >&2
        exit 1
      fi
      IDENTITY="$IDENTITIES"
    fi
    STAGE="$(mktemp -d "${TMPDIR:-/tmp}/xcode-presence-release.XXXXXX")"
    trap 'rm -rf "$STAGE"' EXIT
    RELEASE_SCRATCH="${PRESENCE_RELEASE_SCRATCH:-$STAGE/build}"
    BUILD_MODE=release SCRATCH_DIR="$RELEASE_SCRATCH" "$PROJECT_DIR/scripts/build.sh"
    mkdir -p "$STAGE/image"
    ditto -x -k "$PROJECT_DIR/dist/Xcode Presence.zip" "$STAGE/image"
    APP="$STAGE/image/Xcode Presence.app"
    EXECUTABLE="$APP/Contents/MacOS/XcodePresence"
    HOST_ARCH="$(uname -m)"
    case "$HOST_ARCH" in
      arm64) OTHER_ARCH=x86_64 ;;
      x86_64) OTHER_ARCH=arm64 ;;
      *) printf 'Unsupported build host architecture.\n' >&2; exit 1 ;;
    esac
    BUILD_ARGS=(--package-path "$PROJECT_DIR" --scratch-path "$RELEASE_SCRATCH" -c release --triple "$OTHER_ARCH-apple-macosx13.0")
    swift build "${BUILD_ARGS[@]}" -Xswiftc -module-cache-path -Xswiftc "$RELEASE_SCRATCH/module-cache"
    OTHER_BIN="$(swift build "${BUILD_ARGS[@]}" --show-bin-path)"
    xcrun lipo -create "$EXECUTABLE" "$OTHER_BIN/XcodePresence" -output "$STAGE/universal"
    cp "$STAGE/universal" "$EXECUTABLE"
    codesign --remove-signature "$APP"
    # Remove DWARF debug information before signing the final universal binary.
    xcrun strip -S "$EXECUTABLE"
    xcrun lipo "$EXECUTABLE" -verify_arch arm64
    xcrun lipo "$EXECUTABLE" -verify_arch x86_64
    xattr -cr "$APP"
    codesign --force --options runtime --timestamp --sign "$IDENTITY" "$APP"
    codesign --verify --deep --strict "$APP"
    ln -s /Applications "$STAGE/image/Applications"
    hdiutil create -quiet -ov -volname 'Xcode Presence' -fs HFS+ -format UDZO -srcfolder "$STAGE/image" "$PENDING_DMG"
    codesign --force --timestamp --sign "$IDENTITY" "$PENDING_DMG"
    codesign --verify --strict "$PENDING_DMG"
    printf '\nSigned universal DMG prepared, NOT notarized yet:\n%s\n' "$PENDING_DMG"
    printf 'Do not publish it. Configure the Keychain profile, then run: scripts/release.sh notarize PROFILE_NAME\n'
    ;;
  notarize)
    PROFILE="${2:-}"
    if [[ -z "$PROFILE" || ! -f "$PENDING_DMG" ]]; then
      printf 'Usage: scripts/release.sh notarize PROFILE_NAME (after prepare)\n' >&2
      exit 1
    fi
    SUBMISSION="$OUTPUT_DIR/notarization-submission.json"
    xcrun notarytool submit "$PENDING_DMG" --keychain-profile "$PROFILE" --wait --output-format json > "$SUBMISSION"
    STATUS="$(plutil -extract status raw -o - "$SUBMISSION")"
    if [[ "$STATUS" != Accepted ]]; then
      printf 'Notarization was not accepted. Review the local submission JSON before retrying.\n' >&2
      exit 1
    fi
    xcrun stapler staple "$PENDING_DMG"
    xcrun stapler validate "$PENDING_DMG"
    codesign --verify --strict "$PENDING_DMG"
    spctl --assess --type open --context context:primary-signature "$PENDING_DMG"
    mv "$PENDING_DMG" "$FINAL_DMG"
    (cd "$OUTPUT_DIR" && shasum -a 256 "$BASE_NAME.dmg") > "$OUTPUT_DIR/SHA256SUMS.txt"
    printf '\nNotarized and verified release artifact:\n%s\n' "$FINAL_DMG"
    ;;
  *) printf 'Usage: scripts/release.sh prepare | notarize PROFILE_NAME\n' >&2; exit 1 ;;
esac
