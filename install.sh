#!/bin/zsh

set -euo pipefail

if [[ $# -lt 1 || -z "$1" ]]; then
  print -u2 -- "Usage: ./install.sh <expected-exit-ip> [expected-country]"
  print -u2 -- "Example: ./install.sh 203.0.113.10 US"
  exit 2
fi

readonly EXPECTED_IP="$1"
readonly EXPECTED_COUNTRY_VALUE="${2:-}"
readonly SOURCE_DIR="${0:A:h}"
readonly BIN_DIR="$HOME/.local/bin"
readonly LIB_DIR="$HOME/.local/lib/claude-session-guard"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/claude-session-guard"
readonly LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
readonly PLIST_PATH="$LAUNCH_AGENTS_DIR/io.github.claude-session-guard.macos.plist"
readonly LABEL="io.github.claude-session-guard.macos"

if [[ ! "$EXPECTED_IP" =~ '^([0-9]{1,3}\.){3}[0-9]{1,3}$|^[0-9A-Fa-f:]+$' ]]; then
  print -u2 -- "Invalid IP address: $EXPECTED_IP"
  exit 2
fi

if [[ -n "$EXPECTED_COUNTRY_VALUE" && ! "$EXPECTED_COUNTRY_VALUE" =~ '^[A-Z]{2}$' ]]; then
  print -u2 -- "Country must be a two-letter uppercase code, for example US."
  exit 2
fi

umask 077
mkdir -p "$BIN_DIR" "$LIB_DIR" "$CONFIG_DIR" "$LAUNCH_AGENTS_DIR"

for dependency in /usr/bin/swiftc /usr/bin/curl /usr/bin/nc /usr/bin/osascript; do
  if [[ ! -x "$dependency" ]]; then
    print -u2 -- "Missing required macOS tool: $dependency"
    exit 1
  fi
done

/usr/bin/install -m 700 "$SOURCE_DIR/claude-guard" "$BIN_DIR/claude-guard"
/usr/bin/swiftc -O -framework AppKit \
  "$SOURCE_DIR/ClaudeSleepWatcher.swift" \
  -o "$LIB_DIR/ClaudeSleepWatcher"

if [[ -f "$CONFIG_DIR/config" ]]; then
  cp -p "$CONFIG_DIR/config" "$CONFIG_DIR/config.backup-$(date +%Y%m%d-%H%M%S)"
fi

{
  print -- "CLASH_HOST=127.0.0.1"
  print -- "CLASH_PORT=7897"
  print -- "EXPECTED_EXIT_IP=$EXPECTED_IP"
  print -- "EXPECTED_COUNTRY=$EXPECTED_COUNTRY_VALUE"
} > "$CONFIG_DIR/config"
chmod 600 "$CONFIG_DIR/config"

{
  print -- '<?xml version="1.0" encoding="UTF-8"?>'
  print -- '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
  print -- '<plist version="1.0">'
  print -- '<dict>'
  print -- '  <key>Label</key>'
  print -- "  <string>$LABEL</string>"
  print -- '  <key>ProgramArguments</key>'
  print -- '  <array>'
  print -- "    <string>$LIB_DIR/ClaudeSleepWatcher</string>"
  print -- '  </array>'
  print -- '  <key>RunAtLoad</key>'
  print -- '  <true/>'
  print -- '  <key>KeepAlive</key>'
  print -- '  <true/>'
  print -- '</dict>'
  print -- '</plist>'
} > "$PLIST_PATH"

/usr/bin/plutil -lint "$PLIST_PATH" >/dev/null
/bin/launchctl bootout "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true
/bin/launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH"

print -- "Installed $LABEL."
print -- "Run: $BIN_DIR/claude-guard status"
print -- "Open Claude safely with: $BIN_DIR/claude-guard start"
