#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -n "$(git -C "$PROJECT_DIR" status --porcelain)" ]]; then
  printf 'Commit the intended public files before exporting. The working tree is not clean.\n' >&2
  exit 1
fi
OUTPUT_DIR="${1:-$(dirname "$PROJECT_DIR")/public-exports}"
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"
case "$OUTPUT_DIR/" in "$PROJECT_DIR/"*) printf 'Choose an export folder outside the project.\n' >&2; exit 1 ;; esac
REVISION="$(git -C "$PROJECT_DIR" rev-parse --short HEAD)"
ARCHIVE="$OUTPUT_DIR/XcodePresence-open-source-$REVISION.zip"
git -C "$PROJECT_DIR" archive --format=zip --prefix=XcodePresence/ --output="$ARCHIVE" HEAD
printf 'Public source export: %s\n' "$ARCHIVE"
