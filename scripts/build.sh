#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_MODE="${BUILD_MODE:-release}"
SCRATCH_DIR="${SCRATCH_DIR:-$PROJECT_DIR/.build}"
export CLANG_MODULE_CACHE_PATH="$SCRATCH_DIR/module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$SCRATCH_DIR/module-cache"
APP_NAME="Xcode Presence"
if [[ "${1:-}" == "--preview" ]]; then APP_NAME="Xcode Presence Preview"; fi
swift build --package-path "$PROJECT_DIR" --scratch-path "$SCRATCH_DIR" -c "$BUILD_MODE" \
  -Xswiftc -module-cache-path -Xswiftc "$SCRATCH_DIR/module-cache"
BIN_DIR="$(swift build --package-path "$PROJECT_DIR" --scratch-path "$SCRATCH_DIR" -c "$BUILD_MODE" --show-bin-path)"
STAGE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/xcode-presence-build.XXXXXX")"
trap 'rm -rf "$STAGE_DIR"' EXIT
APP_DIR="$STAGE_DIR/$APP_NAME.app"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN_DIR/XcodePresence" "$APP_DIR/Contents/MacOS/"
cp "$PROJECT_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"
ditto --norsrc --noextattr "$PROJECT_DIR/Resources" "$APP_DIR/Contents/Resources"
if [[ "${1:-}" == "--preview" ]]; then
  /usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier local.xcodepresence.app.preview' "$APP_DIR/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c 'Set :CFBundleDisplayName Xcode Presence Preview' "$APP_DIR/Contents/Info.plist"
fi
# Sign outside synced Documents folders: file providers may add Finder metadata
# to app bundles and invalidate strict validation. The ZIP is made from this stage.
xattr -cr "$APP_DIR"
codesign --force --sign - "$APP_DIR"
codesign --verify --deep --strict "$APP_DIR"
mkdir -p "$PROJECT_DIR/dist"
ditto --norsrc --noextattr "$APP_DIR" "$PROJECT_DIR/dist/$APP_NAME.app"
ditto -c -k --norsrc --noextattr --keepParent "$APP_DIR" "$PROJECT_DIR/dist/$APP_NAME.zip"
printf '\nBuilt: %s\nArchive: %s\n' "$PROJECT_DIR/dist/$APP_NAME.app" "$PROJECT_DIR/dist/$APP_NAME.zip"
