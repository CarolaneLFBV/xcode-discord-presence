#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FORMATTER="${SWIFT_FORMAT:-$(xcrun --find swift-format)}"
if [[ "${1:-}" == "--check" ]]; then
  "$FORMATTER" lint --strict --recursive --configuration "$PROJECT_DIR/.swift-format" \
    "$PROJECT_DIR/Package.swift" "$PROJECT_DIR/Sources" "$PROJECT_DIR/Tests"
elif [[ $# -eq 0 ]]; then
  "$FORMATTER" format --in-place --recursive --configuration "$PROJECT_DIR/.swift-format" \
    "$PROJECT_DIR/Package.swift" "$PROJECT_DIR/Sources" "$PROJECT_DIR/Tests"
else
  printf 'Usage: %s [--check]\n' "$0" >&2
  exit 2
fi
