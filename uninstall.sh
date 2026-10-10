#!/bin/zsh

set -euo pipefail

readonly LABEL="io.github.claude-session-guard.macos"
readonly PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"
readonly BIN_PATH="$HOME/.local/bin/claude-guard"
readonly LIB_PATH="$HOME/.local/lib/claude-session-guard/ClaudeSleepWatcher"
readonly TRASH_DIR="$HOME/.Trash/ClaudeSessionGuard-uninstalled-$(date +%Y%m%d-%H%M%S)"

/bin/launchctl bootout "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true
mkdir -p "$TRASH_DIR"

for path in "$PLIST_PATH" "$BIN_PATH" "$LIB_PATH"; do
  if [[ -e "$path" ]]; then
    mv "$path" "$TRASH_DIR/"
  fi
done

print -- "Uninstalled the watcher and moved its files to: $TRASH_DIR"
print -- "Configuration was preserved at: ${XDG_CONFIG_HOME:-$HOME/.config}/claude-session-guard/config"
