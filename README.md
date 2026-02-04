# 📊 Claude UseBar

macOS menu bar app that monitors Claude Code usage and lets you manage multiple accounts with safe, automatic switching.

## ✨ Features

- 📊 **Real-Time Monitoring** — Displays 5-hour usage limit right in the status bar
- 👥 **Multiple Accounts** — Manage and switch between multiple Claude Code accounts
- 🔄 **Safe Switching** — Automatic rollback system in case of failure
- 💾 **Smart Caching** — 60s cache with 45s polling to avoid unnecessary requests
- 🎨 **Modern UI** — Liquid Glass interface (macOS 26+) with fallback for older versions
- 🔐 **Secure** — Credentials stored in the macOS Keychain

## 📋 Requirements

- 🍎 macOS 14.0+
- 🛠️ Xcode 15.0+
- 🤖 Claude Code installed and configured

## 🚀 Installation

### Build from Source

1. Clone the repository:
```bash
git clone https://github.com/joaoalvess/claude-usebar.git
cd claude-usebar
```

2. Open the project in Xcode:
```bash
open ClaudeUseBar/ClaudeUseBar.xcodeproj
```

3. Build and run (`⌘R`) 🎉

## 🎯 Usage

### First Setup

1. Make sure Claude Code is installed and configured
2. Log in to Claude Code with the desired account
3. Open Claude UseBar
4. Click the icon in the status bar
5. Click "Adicionar Conta" (Add Account)
6. Click "Capturar Conta Atual" (Capture Current Account)

### ➕ Adding More Accounts

1. In Terminal, log in to Claude Code with another account:
```bash
claude logout
claude login
```

2. In Claude UseBar, click "Adicionar Conta" (Add Account)
3. Click "Capturar Conta Atual" (Capture Current Account)

### 🔀 Switching Accounts

1. Click the Claude UseBar icon in the status bar
2. Select the desired account
3. Click "Ativar" (Activate)
4. Restart Claude Code

> ⚠️ **IMPORTANT**: You must restart Claude Code after switching accounts for changes to take effect.

## 🏗️ Architecture

### 📁 Folder Structure

```
ClaudeUseBar/
├── App/                    # Application entry point
├── Models/                 # Data structures
├── Services/
│   ├── Claude/            # Claude Code integration
│   ├── Storage/           # Local persistence
│   └── Network/           # HTTP API client
├── ViewModels/            # Business logic
├── Views/                 # SwiftUI interface
└── Utilities/             # Helpers
```

### 🧩 Main Components

<details>
<summary><strong>📦 Models</strong></summary>

| Component | Description |
|-----------|-------------|
| `Account` | Account stored by the app |
| `OAuthAccount` | Claude config's `.oauthAccount` structure |
| `ClaudeCredentials` | OAuth credentials from Keychain |
| `UsageResponse` | Usage API response |
| `AccountUsage` | Combined account + usage state |

</details>

<details>
<summary><strong>⚙️ Services</strong></summary>

| Component | Description |
|-----------|-------------|
| `ClaudeInstall` | Resolves Claude installation paths |
| `ClaudeConfigStore` | Reads/writes `~/.claude.json` |
| `ClaudeKeychainStore` | Manages Claude Code Keychain |
| `AppKeychainStore` | App's own Keychain |
| `AppAccountStore` | JSON-based account persistence |
| `AnthropicUsageClient` | HTTP client for usage API |
| `AccountSwitcher` | Account switching with atomic rollback |

</details>

<details>
<summary><strong>🧠 ViewModels</strong></summary>

| Component | Description |
|-----------|-------------|
| `UsageViewModel` | Caching, polling, and global state |
| `AddAccountViewModel` | Add account flow |

</details>

<details>
<summary><strong>🖼️ Views</strong></summary>

| Component | Description |
|-----------|-------------|
| `ClaudeUseBarApp` | Entry point, MenuBarExtra |
| `MenuBarLabel` | Icon and percentage in status bar |
| `PopoverContentView` | Main popover container |
| `AccountRowView` | Account row with progress bar |
| `UsageProgressView` | Color-coded progress bar |
| `AddAccountView` | Add account interface |

</details>

## 🔌 Data Sources

### 1. 📄 Claude Code Config
- **Path**: `~/.claude/.claude.json` (preferred) or `~/.claude.json`
- **Field used**: `.oauthAccount`

### 2. 🔑 Keychain
- **Service**: `Claude Code-credentials`
- **Account**: System username
- **Contains**: JSON with `claudeAiOauth.accessToken`

### 3. 🌐 Anthropic API
- **Endpoint**: `GET https://api.anthropic.com/api/oauth/usage`
- **Headers**:
  - `Authorization: Bearer {accessToken}`
  - `anthropic-beta: oauth-2025-04-20`
- **Response**: `five_hour.utilization`, `five_hour.resets_at`

## 🔐 Security

### 🔄 Automatic Rollback

The account switching system implements automatic rollback:

1. Backup current state (config + Keychain)
2. Apply Keychain changes
3. Apply config changes
4. If step 3 fails → rollback Keychain
5. State is always consistent ✅

### 🛡️ Sandbox

The app runs **without sandbox** (required for accessing Claude Code's Keychain). Make sure to review the source code before building.

## 🛠️ Development

### 🗺️ Roadmap

- [ ] 🔔 Notifications when usage exceeds 80%
- [ ] 📱 WidgetKit widget for macOS 14+
- [ ] ⌨️ Shortcuts.app integration
- [ ] ⚡ Real-time updates via WebSocket (when API supports it)

### 🐛 Debug

To verify if the account switch worked:

```bash
# Check active account
cat ~/.claude.json | grep emailAddress

# Check access token in Keychain
security find-generic-password -s "Claude Code-credentials" -w | head -c 100
```

## 🔧 Troubleshooting

| Error | Solution |
|-------|----------|
| "Credenciais não encontradas" | Make sure you're logged in to Claude Code and `~/.claude.json` exists |
| "Token inválido ou expirado" | Run `claude logout` and `claude login` again, then recapture the account |
| "Claude Code está em execução" | Close all Claude Code processes before switching (`pkill -f claude`) |

## 🧰 Tech Stack

| Technology | Usage |
|------------|-------|
| Swift 5.9+ | Main language |
| SwiftUI | User interface |
| macOS Keychain | Secure credential storage |
| URLSession | HTTP requests |
| Anthropic OAuth API | Usage data |

## 📄 License

Copyright © 2026 João Alves. All rights reserved.

## 🤝 Contributing

Suggestions are welcome! Open an [issue](https://github.com/joaoalvess/claude-usebar/issues) or submit a PR.
