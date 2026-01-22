import Foundation

/// ViewModel para o fluxo de adicionar conta
@MainActor
class AddAccountViewModel: ObservableObject {
    @Published private(set) var state: State = .idle
    @Published private(set) var errorMessage: String?

    enum State {
        case idle
        case instructions
        case capturing
        case validating
        case success(Account)
        case error

        var isLoading: Bool {
            if case .capturing = self { return true }
            if case .validating = self { return true }
            return false
        }
    }

    private let accountStore: AppAccountStore
    private let configStore: ClaudeConfigStore
    private let keychainStore: ClaudeKeychainStore
    private let usageClient = AnthropicUsageClient()

    init(accountStore: AppAccountStore) {
        self.accountStore = accountStore

        do {
            self.configStore = try ClaudeConfigStore()
            self.keychainStore = ClaudeKeychainStore()
        } catch {
            fatalError("Erro ao inicializar stores: \(error)")
        }
    }

    /// Inicia o fluxo mostrando instruções
    func showInstructions() {
        state = .instructions
        errorMessage = nil
    }

    /// Captura a conta atual do Claude Code e adiciona ao app
    func captureCurrentAccount() async {
        state = .capturing
        errorMessage = nil

        do {
            // 1. Lê .oauthAccount do config
            let oauthAccount = try configStore.readOAuthAccount()

            // 2. Lê credenciais do Keychain do Claude Code
            let credentials = try keychainStore.readCredentials()

            // Transição para validating
            state = .validating

            // 3. Valida token com API usage
            _ = try await usageClient.fetchUsage(accessToken: credentials.accessToken)

            // 4. Salva no AppAccountStore
            let account = try accountStore.addAccount(
                from: oauthAccount,
                credentials: credentials
            )

            // Sucesso!
            state = .success(account)

        } catch let error as ClaudeConfigStore.ConfigError {
            handleError(error.localizedDescription)

        } catch let error as ClaudeKeychainStore.KeychainError {
            handleError(error.localizedDescription)

        } catch let error as AnthropicUsageClient.ClientError {
            handleError(error.localizedDescription)

        } catch let error as AppAccountStore.StoreError {
            if case .duplicateAccount = error {
                handleError("Esta conta já foi adicionada ao app.")
            } else {
                handleError(error.localizedDescription)
            }

        } catch {
            handleError("Erro inesperado: \(error.localizedDescription)")
        }
    }

    /// Reseta o estado para idle
    func reset() {
        state = .idle
        errorMessage = nil
    }

    // MARK: - Private Helpers

    private func handleError(_ message: String) {
        errorMessage = message
        state = .error
    }

    /// Mensagem de instrução para o usuário
    var instructionsText: String {
        """
        Para adicionar uma nova conta:

        1. Abra o Claude Code no Terminal
        2. Faça login com a conta desejada
        3. Retorne aqui e clique em "Capturar Conta Atual"

        O app irá ler automaticamente as credenciais do Claude Code e adicionar a conta à lista.
        """
    }

    /// Mensagem de sucesso
    func successMessage(for account: Account) -> String {
        """
        Conta adicionada com sucesso!

        \(account.displayName)
        \(account.emailAddress)
        """
    }
}
