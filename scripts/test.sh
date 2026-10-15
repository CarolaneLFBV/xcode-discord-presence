#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRATCH_DIR="${SCRATCH_DIR:-$PROJECT_DIR/.build}"
export CLANG_MODULE_CACHE_PATH="$SCRATCH_DIR/module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$SCRATCH_DIR/module-cache"
swift test --package-path "$PROJECT_DIR" --scratch-path "$SCRATCH_DIR"
