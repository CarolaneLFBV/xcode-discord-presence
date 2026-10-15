#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="${1:-$(dirname "$PROJECT_DIR")/source-backups}"
mkdir -p "$BACKUP_DIR"
BACKUP_DIR="$(cd "$BACKUP_DIR" && pwd)"
case "$BACKUP_DIR/" in "$PROJECT_DIR/"*) printf 'Choose a backup folder outside the source project.\n' >&2; exit 1 ;; esac
ARCHIVE="$BACKUP_DIR/XcodePresence-sources-$(date +%Y%m%d-%H%M%S).zip"
cd "$(dirname "$PROJECT_DIR")"
/usr/bin/zip -qr "$ARCHIVE" "$(basename "$PROJECT_DIR")" -x '*/.git/*' '*/.build/*' '*/.swiftpm/*' '*/dist/*' '*/.DS_Store'
printf 'Sources saved: %s\n' "$ARCHIVE"
