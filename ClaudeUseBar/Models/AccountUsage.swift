import Foundation

/// Estado combinado de uma conta com seus dados de uso
struct AccountUsage: Identifiable, Equatable {
    let account: Account
    var loadingState: LoadingState

    var id: UUID {
        account.id
    }

    enum LoadingState: Equatable {
        case idle
        case loading
        case loaded(UsageResponse, loadedAt: Date)
        case error(UsageError)

        var usage: UsageResponse? {
            if case .loaded(let response, _) = self {
                return response
            }
            return nil
        }

        var error: UsageError? {
            if case .error(let error) = self {
                return error
            }
            return nil
        }

        var isLoading: Bool {
            if case .loading = self {
                return true
            }
            return false
        }
    }

    enum UsageError: Equatable {
        case networkError(String)
        case invalidToken
        case rateLimited
        case unexpectedError(String)

        var localizedDescription: String {
            switch self {
            case .networkError(let message):
                return "Erro de rede: \(message)"
            case .invalidToken:
                return "Token inválido ou expirado"
            case .rateLimited:
                return "Muitas requisições. Tente novamente em alguns minutos."
            case .unexpectedError(let message):
                return "Erro inesperado: \(message)"
            }
        }
    }

    init(account: Account, loadingState: LoadingState = .idle) {
        self.account = account
        self.loadingState = loadingState
    }

    /// Verifica se os dados em cache ainda são válidos (< 60s)
    func isCacheValid(ttl: TimeInterval = 60) -> Bool {
        if case .loaded(_, let loadedAt) = loadingState {
            return Date().timeIntervalSince(loadedAt) < ttl
        }
        return false
    }
}
