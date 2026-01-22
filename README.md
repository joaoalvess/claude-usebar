# Claude UseBar

App de menu bar para macOS que monitora o uso do Claude Code e permite gerenciar múltiplas contas.

## Funcionalidades

- 📊 **Monitoramento em Tempo Real**: Exibe utilização do limite de 5 horas na status bar
- 👥 **Múltiplas Contas**: Gerencie e alterne entre várias contas do Claude Code
- 🔄 **Troca Segura**: Sistema de rollback automático em caso de falha
- 💾 **Cache Inteligente**: Cache de 60s com polling a cada 45s
- 🎨 **Visual Moderno**: Interface com Liquid Glass (macOS 26+) e fallback para versões anteriores

## Requisitos

- macOS 14.0 ou superior
- Xcode 15.0 ou superior
- Claude Code instalado

## Instalação

### Compilar do Código-Fonte

1. Clone o repositório:
```bash
cd /Users/joaoalves/Developer/usebar
```

2. Abra o projeto no Xcode:
```bash
open ClaudeUseBar/ClaudeUseBar.xcodeproj
```

3. Compile e execute (⌘R)

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
├── App/                    # Entry point
├── Models/                 # Estruturas de dados
├── Services/
│   ├── Claude/            # Integração com Claude Code
│   ├── Storage/           # Persistência local
│   └── Network/           # Cliente HTTP API
├── ViewModels/            # Lógica de negócio
├── Views/                 # Interface SwiftUI
└── Utilities/             # Helpers
```

### Componentes Principais

#### Models
- **Account**: Conta armazenada pelo app
- **OAuthAccount**: Estrutura `.oauthAccount` do config Claude
- **ClaudeCredentials**: Credenciais do Keychain
- **UsageResponse**: Resposta da API de uso
- **AccountUsage**: Estado combinado conta + dados de uso

#### Services
- **ClaudeInstall**: Resolve paths de instalação
- **ClaudeConfigStore**: Lê/escreve `~/.claude.json`
- **ClaudeKeychainStore**: Gerencia Keychain do Claude Code
- **AppKeychainStore**: Keychain do próprio app
- **AppAccountStore**: Persistência de contas em JSON
- **AnthropicUsageClient**: Cliente HTTP para API de uso
- **AccountSwitcher**: Troca de contas com rollback

#### ViewModels
- **UsageViewModel**: Cache, polling e estado global
- **AddAccountViewModel**: Fluxo de adicionar conta

#### Views
- **ClaudeUseBarApp**: Entry point, MenuBarExtra
- **MenuBarLabel**: Ícone e porcentagem na status bar
- **PopoverContentView**: Container principal
- **AccountRowView**: Linha por conta com progress bar
- **UsageProgressView**: Barra de progresso colorida
- **AddAccountView**: UI de adicionar conta

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

### Adicionar Novos Recursos

1. **Notificações**: Alertar quando uso > 80%
2. **Widgets**: Widget WidgetKit para macOS 14+
3. **Shortcuts**: Integração com Shortcuts.app
4. **WebSocket**: Updates em tempo real (se API suportar)

### Debug

Para verificar se a troca de conta funcionou:

```bash
# Ver conta ativa
cat ~/.claude.json | grep emailAddress

# Ver access token no Keychain
security find-generic-password -s "Claude Code-credentials" -w | head -c 100
```

## Troubleshooting

### "Credenciais não encontradas"
- Verifique se você está logado no Claude Code
- Confirme que `~/.claude.json` existe
- Execute `security find-generic-password -s "Claude Code-credentials"`

### "Token inválido ou expirado"
- Faça logout e login novamente no Claude Code
- Remova e adicione a conta novamente no app

### "Claude Code está em execução"
- Feche todos os processos do Claude Code antes de trocar de conta
- Execute `pkill -f claude` se necessário

## Licença

Copyright © 2026 João Alves. Todos os direitos reservados.

## Contribuindo

Este é um projeto pessoal, mas sugestões são bem-vindas! Abra uma issue ou PR.
