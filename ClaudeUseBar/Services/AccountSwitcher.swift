import Foundation

/// Gerencia a troca de contas do Claude Code com rollback automático
struct AccountSwitcher {
    private let accountStore: AppAccountStore
    private let configStore: ClaudeConfigStore
    private let keychainStore: ClaudeKeychainStore
    private let processDetector = ProcessDetector()

    struct SwitchResult {
        let success: Bool
        let requiresRestart: Bool
        let message: String
    }

    enum SwitchError: LocalizedError {
        case accountNotFound
        case credentialsNotFound
        case claudeIsRunning
        case backupFailed(Error)
        case keychainWriteFailed(Error)
        case configWriteFailed(Error)
        case rollbackFailed(Error)

        var errorDescription: String? {
            switch self {
            case .accountNotFound:
                return "Conta não encontrada"
            case .credentialsNotFound:
                return "Credenciais da conta não encontradas"
            case .claudeIsRunning:
                return "Claude Code está em execução. Feche-o antes de trocar de conta."
            case .backupFailed(let error):
                return "Erro ao fazer backup: \(error.localizedDescription)"
            case .keychainWriteFailed(let error):
                return "Erro ao atualizar Keychain: \(error.localizedDescription)"
            case .configWriteFailed(let error):
                return "Erro ao atualizar configuração: \(error.localizedDescription)"
            case .rollbackFailed(let error):
                return "ERRO CRÍTICO: Falha ao reverter alterações: \(error.localizedDescription)"
            }
        }
    }

    init(accountStore: AppAccountStore) {
        self.accountStore = accountStore

        do {
            self.configStore = try ClaudeConfigStore()
            self.keychainStore = ClaudeKeychainStore()
        } catch {
            fatalError("Erro ao inicializar AccountSwitcher: \(error)")
        }
    }

    /// Troca para uma conta diferente
    /// - Parameters:
    ///   - account: Conta para ativar
    ///   - force: Se true, pula verificação de processo rodando
    /// - Returns: SwitchResult com resultado da operação
    /// - Throws: SwitchError em caso de erro
    func switchTo(account: Account, force: Bool = false) async throws -> SwitchResult {
        // 1. Verificar se Claude está rodando (a menos que force = true)
        if !force && processDetector.isClaudeRunning {
            throw SwitchError.claudeIsRunning
        }

        // 2. Carregar credenciais da conta alvo
        let targetCredentials: ClaudeCredentials
        do {
            targetCredentials = try await accountStore.credentials(for: account.id)
        } catch {
            throw SwitchError.credentialsNotFound
        }

        // 3. Criar OAuth account para o config
        let targetOAuthAccount = OAuthAccount(
            accountUuid: account.accountUuid,
            emailAddress: account.emailAddress,
            displayName: account.displayName,
            organizationUuid: nil,
            organizationName: account.organizationName,
            organizationRole: nil,
            hasExtraUsageEnabled: nil,
            workspaceRole: nil
        )

        // 4. BACKUP: Salvar estado atual
        let backupConfig: Data
        let backupKeychain: Data

        do {
            backupConfig = try configStore.readConfigData()
            backupKeychain = try keychainStore.readCredentialsData()
        } catch {
            throw SwitchError.backupFailed(error)
        }

        // 5. APPLY 1: Escrever Keychain
        do {
            try keychainStore.writeCredentials(targetCredentials)
        } catch {
            throw SwitchError.keychainWriteFailed(error)
        }

        // 6. APPLY 2: Escrever config
        do {
            try configStore.writeOAuthAccount(targetOAuthAccount)
        } catch {
            // ROLLBACK: Reverter Keychain
            do {
                try keychainStore.restoreCredentials(from: backupKeychain)
            } catch let rollbackError {
                throw SwitchError.rollbackFailed(rollbackError)
            }

            throw SwitchError.configWriteFailed(error)
        }

        // 7. Atualizar lastUsedAt
        try? await accountStore.markAsUsed(account.id)

        // 8. Sucesso!
        return SwitchResult(
            success: true,
            requiresRestart: true,
            message: """
            Conta trocada com sucesso!

            Reinicie o Claude Code para aplicar as mudanças.
            """
        )
    }

    /// Verifica se é necessário reiniciar o Claude Code
    var requiresRestart: Bool {
        processDetector.isClaudeRunning
    }

    /// Lista processos do Claude Code em execução
    var claudeProcesses: [Int32] {
        processDetector.findClaudeProcesses()
    }
}
