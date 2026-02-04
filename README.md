# Claude UseBar

**Claude Code usage in your menu bar, and one-click switching between accounts.**

A small macOS menu bar app that shows how much of the 5-hour Claude Code limit each of your accounts has used, and swaps the account Claude Code is logged into without going through `logout` and `login` again.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-000000?logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-SwiftUI-F05138?logo=swift&logoColor=white)
![No dependencies](https://img.shields.io/badge/dependencies-none-lightgrey)

## Features

- **Usage at a glance**: the menu bar shows the active account's 5-hour usage. The popover lists every account with a color-coded bar (green, yellow, orange, red) and the time until its window resets.
- **Multiple accounts**: capture the account Claude Code is logged into, then add as many as you need. Each one is checked against the usage API, and duplicates are rejected.
- **One-click switching**: activating an account writes its credentials into Claude Code's Keychain item and config. If the config write fails, the Keychain change is rolled back.
- **Safe by default**: switching is blocked while Claude Code is running, and saved credentials live in the macOS Keychain.

The interface is in Brazilian Portuguese.

## How it works

| Source | What the app reads or writes |
|---|---|
| Claude Code config | `oauthAccount` in `~/.claude/.claude.json`, or `~/.claude.json` as a fallback |
| Claude Code Keychain item | Service `Claude Code-credentials`, account = your macOS user name |
| Anthropic usage API | `GET https://api.anthropic.com/api/oauth/usage`, for the `five_hour` utilization and reset time |
| App storage | One Keychain item per saved account, plus account metadata in `~/Library/Application Support/ClaudeUseBar/accounts.json` |

Usage refreshes in the background, with a short per-account cache to avoid unnecessary requests. The app is not sandboxed, because it needs Claude Code's Keychain item and config file. Review the source before building it.

## Getting started

Requirements: macOS 14 or later, Xcode 15 or later, and Claude Code logged in at least once (the app needs its config file).

```bash
git clone https://github.com/joaoalvess/claude-usebar.git
cd claude-usebar
open ClaudeUseBar.xcodeproj
```

In Xcode, pick a signing team (or "Sign to Run Locally") and run the `ClaudeUseBar` scheme. macOS asks for Keychain access the first time.

### Adding accounts

1. Log in to Claude Code with the first account.
2. Open the menu bar popover, choose **Adicionar Conta**, then **Capturar Conta Atual**.
3. For each extra account, log in to it in the terminal and capture it the same way:

```bash
claude auth logout
claude auth login
```

To switch, quit every Claude Code session and choose **Ativar** on the account you want.

## Troubleshooting

| Message | What to do |
|---|---|
| "Credenciais do Claude Code não encontradas no Keychain" | Log in to Claude Code (`claude auth login`), then capture the account again |
| "Token inválido ou expirado" | Log in with that account again and recapture it |
| "Claude Code está em execução. Feche-o antes de trocar de conta." | Quit every Claude Code session, then switch |
| The app quits right after launch | Claude Code's config file is missing: run Claude Code once |

## Project structure

| Path | Role |
|---|---|
| `ClaudeUseBar/App/` | App entry point (`MenuBarExtra`) |
| `ClaudeUseBar/Models/` | Accounts, credentials and usage types |
| `ClaudeUseBar/Services/Claude/` | Claude Code's config file and Keychain item |
| `ClaudeUseBar/Services/Storage/` | The app's own Keychain items and account list |
| `ClaudeUseBar/Services/Network/` | Usage API client |
| `ClaudeUseBar/Services/AccountSwitcher.swift` | The switch, with backup and rollback |
| `ClaudeUseBar/ViewModels/` | Polling, cache and the add-account flow |
| `ClaudeUseBar/Views/` | Menu bar label and popover |

Built with SwiftUI, Combine and the Security framework, with no third-party dependencies.

## Roadmap

- [ ] Notifications when usage passes 80%
- [ ] WidgetKit widget
- [ ] Shortcuts integration

## License

Copyright © 2026 João Alves. All rights reserved.
