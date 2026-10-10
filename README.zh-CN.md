# Claude Session Guard for macOS

> 仅适用于 macOS：在系统睡眠前退出 Claude，并在使用 Clash/Mihomo 时校验出口一致性。

[English](README.md)

Claude Session Guard 会在 macOS 合盖或睡眠前退出 Claude Desktop，并停止当前用户下进程名为 `claude` 的 CLI。唤醒后不会自动重启 Claude；用户必须通过出口检查后主动启动。

这个项目解决的是睡眠会话残留和出口漂移问题。它不能把共享代理 IP 变“干净”，不能绕过地区限制，也不能保证账号不被限制。

## 功能

- 监听 macOS 原生睡眠通知，包括合盖睡眠。
- 退出 Claude Desktop 和当前用户的 Claude CLI。
- 检查 Clash/Mihomo、代理端口和 Vortex 冲突。
- 同时验证显式代理与正常 TUN/系统路径。
- 出口 IP 或可选国家代码变化时拒绝启动 Claude。
- 不保存代理用户名、密码、Cookie 或 Claude API Key。
- `clean` 仅安全退出 Claude，不删除账号数据和诊断日志。

## 环境要求

- macOS；当前版本已在 macOS 15 上测试。
- 已安装 Claude Desktop。
- Clash Verge Rev 或其他提供本地 HTTP 代理的 Clash/Mihomo 客户端。
- Apple Command Line Tools，可使用 `swiftc`。

不支持 Linux 和 Windows。

## 安装

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/claude-session-guard-macos.git
cd claude-session-guard-macos
./install.sh 你的固定出口IP US
```

安装内容全部位于当前用户目录，不需要管理员权限：

- `~/.local/bin/claude-guard`
- `~/.local/lib/claude-session-guard/ClaudeSleepWatcher`
- `~/.config/claude-session-guard/config`
- `~/Library/LaunchAgents/io.github.claude-session-guard.macos.plist`

## 使用

```bash
~/.local/bin/claude-guard status
~/.local/bin/claude-guard start
~/.local/bin/claude-guard stop
~/.local/bin/claude-guard clean
```

为了让启动检查有效，请通过 `claude-guard start` 打开 Claude，不要直接点击应用图标。

## 工作流程

启动前：

```text
Vortex 未运行
  -> Clash/Mihomo 正常
  -> 本地代理端口正常
  -> 显式代理出口匹配
  -> TUN/系统出口匹配
  -> 国家代码匹配
  -> 启动 Claude
```

睡眠前：

```text
macOS 睡眠通知
  -> ClaudeSleepWatcher
  -> claude-guard stop
  -> 唤醒后保持关闭
```

## 配置

配置文件位于 `~/.config/claude-session-guard/config`：

```ini
CLASH_HOST=127.0.0.1
CLASH_PORT=7897
EXPECTED_EXIT_IP=203.0.113.10
EXPECTED_COUNTRY=US
```

`203.0.113.10` 是文档示例地址，必须换成你的固定出口。

## 测试

```bash
./tests/smoke.sh

# 可选：执行真实出口检查
EXPECTED_EXIT_IP=你的固定出口IP EXPECTED_COUNTRY=US ./tests/smoke.sh
```

测试不会安装 LaunchAgent，也不会退出 Claude。

## 卸载

```bash
./uninstall.sh
```

安装文件会移动到废纸篓，配置文件默认保留。

## 安全与隐私边界

- 无法判断共享代理 IP 的服务端信誉。
- 不会绕过 Anthropic 的支持地区政策或其他服务条款。
- 不会关闭浏览器中的 Claude 标签页，也不会退出其他设备。
- 不会删除 Cookie、日志、账号数据或其他本地证据。
- 用户直接点击 Claude 图标可以绕过启动检查。

提交 Issue 时请勿包含代理凭据、账号 Cookie、订阅配置或未脱敏日志。

## 免责声明

本项目是独立社区项目，与 Anthropic 无关联。Claude 是 Anthropic 的商标。

## License

[MIT](LICENSE)
