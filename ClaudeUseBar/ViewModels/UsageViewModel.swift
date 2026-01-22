import Foundation
import Combine

/// ViewModel central que gerencia estado, cache e polling de dados de uso
@MainActor
class UsageViewModel: ObservableObject {
    @Published private(set) var accountUsages: [AccountUsage] = []
    @Published private(set) var activeAccountUuid: String?
    @Published private(set) var isRefreshing = false

    private let accountStore: AppAccountStore
    private let usageClient = AnthropicUsageClient()
    private let configStore: ClaudeConfigStore

    private var pollingTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    private let cacheTTL: TimeInterval = 60 // Cache válido por 60 segundos
    private let pollingInterval: TimeInterval = 45 // Polling a cada 45 segundos

    init(accountStore: AppAccountStore) {
        self.accountStore = accountStore

        do {
            self.configStore = try ClaudeConfigStore()
        } catch {
            fatalError("Erro ao inicializar ClaudeConfigStore: \(error)")
        }

        setupObservers()
        loadActiveAccount()

        // Inicia refresh e polling assincronamente
        Task {
            await refreshAll()
            startPolling()
        }
    }

    deinit {
        pollingTask?.cancel()
    }

    // MARK: - Public Methods

    /// Inicia polling automático
    func startPolling() {
        stopPolling()

        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))

                if !Task.isCancelled {
                    await refreshAll()
                }
            }
        }
    }

    /// Para polling automático
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    /// Atualiza dados de todas as contas
    func refreshAll() async {
        isRefreshing = true
        defer { isRefreshing = false }

        // Sincroniza com accountStore
        syncAccountUsages()

        // Atualiza cada conta que precisa de refresh (cache expirado ou nunca carregado)
        await withTaskGroup(of: Void.self) { group in
            for usage in accountUsages where !usage.isCacheValid(ttl: cacheTTL) {
                group.addTask {
                    await self.fetchUsage(for: usage.account.id)
                }
            }
        }
    }

    /// Atualiza dados de uma conta específica
    func refreshAccount(_ accountId: UUID) async {
        await fetchUsage(for: accountId)
    }

    /// Texto para exibir na status bar (ex: "12%")
    var statusBarText: String {
        guard let activeUuid = activeAccountUuid,
              let activeUsage = accountUsages.first(where: { $0.account.accountUuid == activeUuid }),
              case .loaded(let response, _) = activeUsage.loadingState else {
            return "—"
        }

        return "\(response.utilizationPercentage)%"
    }

    // MARK: - Private Methods

    private func setupObservers() {
        // Observa mudanças nas contas
        accountStore.$accounts
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.syncAccountUsages()
                }
            }
            .store(in: &cancellables)
    }

    private func loadActiveAccount() {
        do {
            let oauthAccount = try configStore.readOAuthAccount()
            activeAccountUuid = oauthAccount.accountUuid
        } catch {
            print("Erro ao carregar conta ativa: \(error)")
            activeAccountUuid = nil
        }
    }

    /// Sincroniza accountUsages com accounts do store
    private func syncAccountUsages() {
        let accounts = accountStore.accounts

        // Remove usages de contas que não existem mais
        accountUsages.removeAll { usage in
            !accounts.contains(where: { $0.id == usage.account.id })
        }

        // Adiciona novas contas
        for account in accounts {
            if !accountUsages.contains(where: { $0.account.id == account.id }) {
                accountUsages.append(AccountUsage(account: account))
            }
        }

        // Ordena pela ordem das contas
        accountUsages.sort { $0.account.order < $1.account.order }
    }

    /// Busca dados de uso para uma conta
    private func fetchUsage(for accountId: UUID) async {
        guard let index = accountUsages.firstIndex(where: { $0.account.id == accountId }) else {
            return
        }

        // Marca como loading
        accountUsages[index].loadingState = .loading

        do {
            // Busca credenciais
            let credentials = try accountStore.credentials(for: accountId)

            // Busca usage
            let response = try await usageClient.fetchUsage(accessToken: credentials.accessToken)

            // Atualiza estado
            accountUsages[index].loadingState = .loaded(response, loadedAt: Date())

        } catch let error as AnthropicUsageClient.ClientError {
            // Mapeia erros do client
            let usageError: AccountUsage.UsageError

            switch error {
            case .invalidToken:
                usageError = .invalidToken
            case .rateLimited:
                usageError = .rateLimited
            case .networkError(let innerError):
                usageError = .networkError(innerError.localizedDescription)
            default:
                usageError = .unexpectedError(error.localizedDescription)
            }

            accountUsages[index].loadingState = .error(usageError)

        } catch {
            // Outros erros
            accountUsages[index].loadingState = .error(.unexpectedError(error.localizedDescription))
        }
    }

    /// Recarrega conta ativa do config
    func reloadActiveAccount() {
        loadActiveAccount()
    }
}
