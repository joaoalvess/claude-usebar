# 📊 Claude UseBar

App de menu bar para macOS que monitora o uso do Claude Code e permite gerenciar múltiplas contas com troca segura e automática.

## Funcionalidades

- 📊 **Monitoramento em Tempo Real** — Exibe utilização do limite de 5 horas direto na status bar
- 👥 **Múltiplas Contas** — Gerencie e alterne entre várias contas do Claude Code
- 🔄 **Troca Segura** — Sistema de rollback automático em caso de falha na troca
- 💾 **Cache Inteligente** — Cache de 60s com polling a cada 45s para evitar requisições desnecessárias
- 🎨 **Visual Moderno** — Interface com Liquid Glass (macOS 26+) e fallback para versões anteriores
- 🔐 **Segurança** — Credenciais armazenadas no Keychain do macOS

## Requisitos

- macOS 14.0+
- Xcode 15.0+
- Claude Code instalado e configurado

## Instalação

### Compilar do Código-Fonte

1. Clone o repositório:
```bash
git clone https://github.com/joaoalvess/claude-usebar.git
cd claude-usebar
```

2. Abra o projeto no Xcode:
```bash
open ClaudeUseBar/ClaudeUseBar.xcodeproj
```

3. Compile e execute (`⌘R`)

## Como Usar

### Primeira Configuração

1. Certifique-se de que o Claude Code está instalado e configurado
2. Faça login no Claude Code com a conta desejada
3. Abra o Claude UseBar
4. Clique no ícone na status bar
5. Clique em "Adicionar Conta"
6. Clique em "Capturar Conta Atual"

### Adicionar Mais Contas

1. No Terminal, faça login no Claude Code com outra conta:
```bash
claude logout
claude login
```

2. No Claude UseBar, clique em "Adicionar Conta"
3. Clique em "Capturar Conta Atual"

### Trocar de Conta

1. Clique no ícone do Claude UseBar na status bar
2. Selecione a conta desejada
3. Clique em "Ativar"
4. Reinicie o Claude Code

**⚠️ IMPORTANTE**: Você deve reiniciar o Claude Code após trocar de conta para que as mudanças tenham efeito.

## Arquitetura

### Estrutura de Pastas

```
ClaudeUseBar/
├── App/                    # Ponto de entrada da aplicação
├── Models/                 # Estruturas de dados
├── Services/
│   ├── Claude/            # Integração com Claude Code
│   ├── Storage/           # Persistência local
│   └── Network/           # Cliente HTTP para API
├── ViewModels/            # Lógica de negócio
├── Views/                 # Interface SwiftUI
└── Utilities/             # Utilitários
```

### Componentes Principais

<details>
<summary><strong>Models</strong></summary>

| Componente | Descrição |
|------------|-----------|
| `Account` | Conta armazenada pelo app |
| `OAuthAccount` | Estrutura `.oauthAccount` do config do Claude |
| `ClaudeCredentials` | Credenciais OAuth do Keychain |
| `UsageResponse` | Resposta da API de uso |
| `AccountUsage` | Estado combinado conta + dados de uso |

</details>

<details>
<summary><strong>Services</strong></summary>

| Componente | Descrição |
|------------|-----------|
| `ClaudeInstall` | Resolve paths de instalação do Claude |
| `ClaudeConfigStore` | Lê/escreve `~/.claude.json` |
| `ClaudeKeychainStore` | Gerencia Keychain do Claude Code |
| `AppKeychainStore` | Keychain do próprio app |
| `AppAccountStore` | Persistência de contas em JSON |
| `AnthropicUsageClient` | Cliente HTTP para API de uso |
| `AccountSwitcher` | Troca de contas com rollback atômico |

</details>

<details>
<summary><strong>ViewModels</strong></summary>

| Componente | Descrição |
|------------|-----------|
| `UsageViewModel` | Cache, polling e estado global |
| `AddAccountViewModel` | Fluxo de adicionar conta |

</details>

<details>
<summary><strong>Views</strong></summary>

| Componente | Descrição |
|------------|-----------|
| `ClaudeUseBarApp` | Ponto de entrada, MenuBarExtra |
| `MenuBarLabel` | Ícone e porcentagem na status bar |
| `PopoverContentView` | Container principal do popover |
| `AccountRowView` | Linha por conta com barra de progresso |
| `UsageProgressView` | Barra de progresso com cores dinâmicas |
| `AddAccountView` | Interface de adicionar conta |

</details>

## Fontes de Dados

### 1. Config Claude Code
- **Path**: `~/.claude/.claude.json` (preferencial) ou `~/.claude.json`
- **Campo usado**: `.oauthAccount`

### 2. Keychain
- **Service**: `Claude Code-credentials`
- **Account**: Nome de usuário do sistema
- **Contém**: JSON com `claudeAiOauth.accessToken`

### 3. API Anthropic
- **Endpoint**: `GET https://api.anthropic.com/api/oauth/usage`
- **Headers**:
  - `Authorization: Bearer {accessToken}`
  - `anthropic-beta: oauth-2025-04-20`
- **Response**: `five_hour.utilization`, `five_hour.resets_at`

## Segurança

### Rollback Automático

O sistema de troca de contas implementa rollback automático:

1. Backup do estado atual (config + Keychain)
2. Aplica mudanças no Keychain
3. Aplica mudanças no config
4. Se step 3 falhar → rollback do Keychain
5. Estado sempre consistente

### Sandbox

O app roda **sem sandbox** (necessário para acesso ao Keychain do Claude Code). Certifique-se de revisar o código antes de compilar.

## Desenvolvimento

### Roadmap

- [ ] Notificações quando uso ultrapassar 80%
- [ ] Widget via WidgetKit para macOS 14+
- [ ] Integração com Shortcuts.app
- [ ] Updates em tempo real via WebSocket (quando API suportar)

### Debug

Para verificar se a troca de conta funcionou:

```bash
# Ver conta ativa
cat ~/.claude.json | grep emailAddress

# Ver access token no Keychain
security find-generic-password -s "Claude Code-credentials" -w | head -c 100
```

## Troubleshooting

| Erro | Solução |
|------|---------|
| "Credenciais não encontradas" | Verifique se está logado no Claude Code e se `~/.claude.json` existe |
| "Token inválido ou expirado" | Faça `claude logout` e `claude login` novamente, depois recapture a conta |
| "Claude Code está em execução" | Feche todos os processos do Claude Code antes de trocar (`pkill -f claude`) |

## Tech Stack

| Tecnologia | Uso |
|------------|-----|
| Swift 5.9+ | Linguagem principal |
| SwiftUI | Interface do usuário |
| macOS Keychain | Armazenamento seguro de credenciais |
| URLSession | Requisições HTTP |
| Anthropic OAuth API | Dados de uso |

## Licença

Copyright © 2026 João Alves. Todos os direitos reservados.

## Contribuindo

Sugestões são bem-vindas! Abra uma [issue](https://github.com/joaoalvess/claude-usebar/issues) ou envie um PR.
