#!/bin/zsh

set -euo pipefail

readonly ROOT_DIR="${0:A:h:h}"
readonly BUILD_DIR="$ROOT_DIR/.build"

mkdir -p "$BUILD_DIR"

zsh -n "$ROOT_DIR/claude-guard"
zsh -n "$ROOT_DIR/install.sh"
zsh -n "$ROOT_DIR/uninstall.sh"

/usr/bin/swiftc -warnings-as-errors -framework AppKit \
  "$ROOT_DIR/ClaudeSleepWatcher.swift" \
  -o "$BUILD_DIR/ClaudeSleepWatcher"

"$ROOT_DIR/claude-guard" help >/dev/null

if [[ -n "${EXPECTED_EXIT_IP:-}" ]]; then
  "$ROOT_DIR/claude-guard" check
else
  print -- "Skipping live route check; EXPECTED_EXIT_IP is not set."
fi

print -- "Smoke tests passed."
