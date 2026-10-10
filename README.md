# Claude Session Guard for macOS

> macOS-only sleep guard and egress consistency checker for Claude Desktop when used with Clash/Mihomo.

[简体中文](README.zh-CN.md)

Claude Session Guard closes Claude Desktop and the current user's Claude CLI process before macOS sleeps. After wake, it keeps Claude closed until you explicitly start it through a route check.

The project is designed to prevent stale sessions and accidental egress changes. It does **not** make a proxy IP "clean," bypass regional restrictions, or guarantee that an account will not be restricted.

## Features

- Observes the native macOS sleep notification, including lid-close sleep.
- Gracefully quits Claude Desktop and stops exact-name `claude` CLI processes.
- Checks that Clash/Mihomo is running and its local HTTP proxy port is available.
- Refuses to open Claude when Vortex is competing for the proxy path.
- Verifies both the explicit Clash proxy path and the normal TUN/system path.
- Pins an expected egress IP and, optionally, a two-letter country code.
- Never stores proxy usernames or passwords.
- Does not delete cookies, account data, or diagnostic logs.

## Requirements

- macOS. The current release has been tested on macOS 15.
- Claude Desktop installed as `Claude.app`.
- Clash Verge Rev or another Clash/Mihomo setup exposing a local HTTP proxy.
- Apple Command Line Tools with `swiftc` available.
- Built-in `curl`, `nc`, `osascript`, and `launchctl` commands.

This project is not intended for Linux or Windows.

## Install

Clone the repository, then provide the stable egress IP and optional country code that Claude is expected to see:

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/claude-session-guard-macos.git
cd claude-session-guard-macos
./install.sh YOUR_STABLE_EXIT_IP US
```

The installer creates only user-scoped files:

- `~/.local/bin/claude-guard`
- `~/.local/lib/claude-session-guard/ClaudeSleepWatcher`
- `~/.config/claude-session-guard/config`
- `~/Library/LaunchAgents/io.github.claude-session-guard.macos.plist`

No administrator privileges are required. Existing guard configuration is backed up before it is replaced.

## Usage

```bash
# Show Claude process state and verify both network paths
~/.local/bin/claude-guard status

# Open Claude only when all checks pass
~/.local/bin/claude-guard start

# Gracefully stop Claude Desktop and the user's Claude CLI
~/.local/bin/claude-guard stop

# Safe alias for stop; no local account data is deleted
~/.local/bin/claude-guard clean
```

For the launch guard to be effective, start Claude with `claude-guard start` instead of opening the application directly.

## How it works

Before launch:

```text
Vortex stopped
  -> Clash/Mihomo running
  -> local proxy port available
  -> explicit-proxy exit matches
  -> TUN/system exit matches
  -> optional country matches
  -> open Claude
```

Before sleep:

```text
macOS willSleepNotification
  -> ClaudeSleepWatcher
  -> claude-guard stop
  -> Claude remains closed after wake
```

The exit check uses `https://claude.ai/cdn-cgi/trace`. No account cookie or Claude API key is sent by the guard.

## Configuration

Edit `~/.config/claude-session-guard/config`:

```ini
CLASH_HOST=127.0.0.1
CLASH_PORT=7897
EXPECTED_EXIT_IP=203.0.113.10
EXPECTED_COUNTRY=US
```

`203.0.113.10` is a documentation address. Replace it with your own expected exit.

## Uninstall

```bash
./uninstall.sh
```

The uninstaller stops the LaunchAgent and moves installed binaries and the plist to the Trash. It preserves the configuration file.

## Test locally

```bash
./tests/smoke.sh

# Optional live route check
EXPECTED_EXIT_IP=YOUR_STABLE_EXIT_IP EXPECTED_COUNTRY=US ./tests/smoke.sh
```

The smoke test checks Zsh syntax, compiles the Swift watcher, and runs an optional live route check. It does not install the LaunchAgent or stop Claude.

## Security and privacy boundaries

- This tool cannot determine whether a shared proxy IP has a good server-side reputation.
- It does not bypass Anthropic's supported-region policy or other service terms.
- It does not close Claude browser tabs or sign out other devices.
- It does not erase local evidence, cookies, logs, or account data.
- A local user can bypass the guard by opening Claude directly.
- The sleep hook has an eight-second timeout and never intentionally blocks system sleep indefinitely.

Please do not include proxy credentials, account cookies, or private logs in bug reports.

## Contributing

Issues and small pull requests are welcome. Include your macOS version, Clash/Mihomo client, and sanitized command output. Never post credentials or complete subscription configurations.

## Disclaimer

This is an independent community project and is not affiliated with Anthropic. Claude is a trademark of Anthropic.

## License

[MIT](LICENSE)
