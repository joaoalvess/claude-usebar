# Verificação de Implementação - Claude UseBar

## ✅ Checklist de Arquivos

### Models (5 arquivos)
- [x] `Account.swift` - Estrutura de conta armazenada
- [x] `OAuthAccount.swift` - Estrutura `.oauthAccount` do Claude
- [x] `ClaudeCredentials.swift` - Credenciais do Keychain
- [x] `UsageResponse.swift` - Resposta da API de uso
- [x] `AccountUsage.swift` - Estado combinado conta + uso

### Services/Claude (3 arquivos)
- [x] `ClaudeInstall.swift` - Resolve paths de instalação
- [x] `ClaudeConfigStore.swift` - Lê/escreve `~/.claude.json`
- [x] `ClaudeKeychainStore.swift` - Interface com Keychain do Claude

### Services/Storage (2 arquivos)
- [x] `AppKeychainStore.swift` - Keychain do app
- [x] `AppAccountStore.swift` - Persistência de contas JSON

### Services/Network (1 arquivo)
- [x] `AnthropicUsageClient.swift` - Cliente HTTP API usage

### Services (1 arquivo)
- [x] `AccountSwitcher.swift` - Switch de contas com rollback

### ViewModels (2 arquivos)
- [x] `UsageViewModel.swift` - Estado global, cache, polling
- [x] `AddAccountViewModel.swift` - Fluxo adicionar conta

### Views (5 arquivos)
- [x] `MenuBarLabel.swift` - Label na status bar
- [x] `PopoverContentView.swift` - Container popover
- [x] `AccountRowView.swift` - Linha por conta
- [x] `UsageProgressView.swift` - Barra de progresso
- [x] `AddAccountView.swift` - UI adicionar conta

### App (1 arquivo)
- [x] `ClaudeUseBarApp.swift` - Entry point MenuBarExtra

### Utilities (2 arquivos)
- [x] `ProcessDetector.swift` - Detecta Claude rodando
- [x] `TimeFormatter.swift` - Formata tempo/datas

### Configuração (4 arquivos)
- [x] `ClaudeUseBar.entitlements` - Permissões non-sandboxed
- [x] `Info.plist` - Metadados do app
- [x] `Assets.xcassets/Contents.json` - Asset catalog
- [x] `project.pbxproj` - Projeto Xcode

### Total: 27 arquivos Swift + 4 configuração = 31 arquivos

## 🧪 Plano de Testes Manuais

### 1. Compilação
```bash
cd /Users/joaoalves/Developer/usebar/ClaudeUseBar
open ClaudeUseBar.xcodeproj
# No Xcode: ⌘R para compilar e rodar
```

**Esperado**: App compila sem erros e aparece ícone na status bar.

### 2. Adicionar Primeira Conta

**Pré-requisitos**:
- Claude Code instalado
- Logado em uma conta

**Passos**:
1. Clicar no ícone do Claude UseBar na status bar
2. Clicar "Adicionar Conta"
3. Seguir instruções na tela
4. Clicar "Capturar Conta Atual"

**Esperado**:
- Sucesso: "Conta adicionada com sucesso!"
- Conta aparece na lista com nome, email, usage
- Porcentagem aparece na status bar (ex: "12%")
- Badge "Ativa" na conta

**Verificar**:
```bash
# Arquivo accounts.json foi criado
cat ~/Library/Application\ Support/ClaudeUseBar/accounts.json

# Credenciais salvas no Keychain do app
security find-generic-password -s "com.joaoalves.claudeusebar.account.*" -a "*"
```

### 3. Visualizar Usage

**Esperado**:
- Barra de progresso com cor:
  - Verde: 0-59%
  - Amarelo: 60-79%
  - Laranja: 80-99%
  - Vermelho: 100%
- Texto "Reseta em Xh Ym"
- Porcentagem na status bar atualiza

### 4. Adicionar Segunda Conta

**Pré-requisitos**:
1. Fazer logout do Claude Code:
```bash
claude logout
```

2. Fazer login com outra conta:
```bash
claude login
```

**Passos**:
1. No Claude UseBar, clicar "Adicionar Conta"
2. Clicar "Capturar Conta Atual"

**Esperado**:
- Segunda conta adicionada
- Lista mostra ambas as contas
- Primeira conta continua com badge "Ativa"
- Segunda conta tem botão "Ativar"

### 5. Trocar de Conta

**IMPORTANTE**: Fechar Claude Code antes deste teste!

**Passos**:
1. Na segunda conta, clicar "Ativar"
2. Ler mensagem de confirmação
3. Clicar "OK"

**Esperado**:
- Alerta: "Reinicie o Claude Code"
- Segunda conta agora tem badge "Ativa"
- Primeira conta tem botão "Ativar"

**Verificar switch funcionou**:
```bash
# Config foi atualizado
cat ~/.claude.json | grep emailAddress
# Deve mostrar email da segunda conta

# Keychain foi atualizado
security find-generic-password -s "Claude Code-credentials" -w | head -c 100
# Deve mostrar access token da segunda conta
```

**Validar**:
1. Abrir novo terminal
2. Rodar qualquer comando Claude Code
3. Verificar que está usando a segunda conta

### 6. Refresh Manual

**Passos**:
1. Clicar no botão refresh (↻) no header do popover

**Esperado**:
- Ícone gira enquanto carrega
- Todas as contas atualizam seus dados de uso
- Cache é atualizado

### 7. Polling Automático

**Passos**:
1. Deixar app aberto por 1 minuto
2. Observar status bar

**Esperado**:
- A cada 45 segundos, dados são atualizados automaticamente
- Porcentagem na status bar pode mudar se houver uso

### 8. Remover Conta

**Passos**:
1. Clicar ícone lixeira na conta (não ativa)
2. Confirmar remoção

**Esperado**:
- Conta removida da lista
- Credenciais removidas do Keychain do app
- Arquivo accounts.json atualizado

**Verificar**:
```bash
# Conta removida
cat ~/Library/Application\ Support/ClaudeUseBar/accounts.json

# Credenciais removidas
security find-generic-password -s "com.joaoalves.claudeusebar.account.*" -a "*"
```

### 9. Estado Vazio

**Passos**:
1. Remover todas as contas

**Esperado**:
- Mensagem: "Nenhuma conta adicionada"
- Ícone ilustrativo
- Botão "Adicionar Conta" visível
- Status bar mostra "—"

### 10. Erros

#### 10.1. Token Expirado

**Simular**:
1. Adicionar conta
2. Manualmente editar Keychain para token inválido:
```bash
# Não execute isso, apenas exemplo
# security delete-generic-password -s "com.joaoalves.claudeusebar.account.UUID"
```

**Esperado**:
- Mensagem de erro: "Token inválido ou expirado"
- Ícone de alerta na conta

#### 10.2. Claude Rodando Durante Switch

**Simular**:
1. Abrir Claude Code
2. Tentar trocar conta

**Esperado**:
- Erro: "Claude Code está em execução. Feche-o antes de trocar de conta."

#### 10.3. Offline

**Simular**:
1. Desconectar internet
2. Tentar adicionar conta ou refresh

**Esperado**:
- Mensagem de erro de rede
- Cache antigo ainda visível (se existir)

### 11. Performance

**Verificar**:
- App ocupa < 50MB de RAM
- CPU < 1% em idle
- Polling não causa lag visível
- UI responsiva (< 100ms para abrir popover)

### 12. Visual

**macOS 14-25**:
- Background com `Color(nsColor: .controlBackgroundColor)`
- Material semi-transparente

**macOS 26+** (quando disponível):
- Liquid Glass nativo
- Efeito blur premium

## 🐛 Bugs Conhecidos / Limitações

### Limitações Esperadas:
1. **Non-Sandboxed**: App precisa rodar sem sandbox para acessar Keychain do Claude
2. **Reinício Manual**: Usuário deve reiniciar Claude Code após switch
3. **Liquid Glass**: Implementação completa requer macOS 26+ (fallback funcional)

### Possíveis Issues:
1. **Path do Config**: Se usuário tiver config em local não-padrão
2. **Keychain Access**: Primeira vez pode pedir permissão
3. **Rate Limiting**: API pode limitar após muitos requests

## ✨ Funcionalidades Futuras (Pós-MVP)

- [ ] Notificações push quando uso > 80%
- [ ] Widget para macOS 14+
- [ ] Atalhos no Shortcuts.app
- [ ] WebSocket para updates instantâneos
- [ ] Histórico de uso por dia/semana
- [ ] Export de dados para CSV
- [ ] Temas customizáveis
- [ ] Suporte para Enterprise accounts

## 📝 Notas de Desenvolvimento

### Decisões de Design:
1. **Cache de 60s**: Balanceia entre freshness e API calls
2. **Polling de 45s**: Garante que nunca ultrapassamos TTL
3. **Rollback atômico**: Previne estados inconsistentes
4. **ObservableObject**: StateObject para lifecycle management
5. **Actor para HTTP**: Thread-safety no cliente de rede

### Trade-offs:
- **Non-Sandboxed**: Necessário mas reduz segurança
- **JSON plano**: Simples mas não é criptografado
- **Polling vs WebSocket**: Polling é mais simples e confiável
- **SwiftUI puro**: Mais moderno mas requer macOS 14+

## 🚀 Deployment

### Para Distribuição:
1. Archive no Xcode (Product > Archive)
2. Export como macOS App
3. Notarize na Apple (opcional para público)
4. Distribuir DMG ou via Homebrew

### Assinatura de Código:
```bash
# Adicionar Development Team no Xcode
# Build Settings > Signing > Team
```

---

**Data da Verificação**: 2026-01-22
**Versão**: 1.0
**Status**: ✅ Implementação Completa
