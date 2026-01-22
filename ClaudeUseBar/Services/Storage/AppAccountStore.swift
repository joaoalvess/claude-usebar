import Foundation
import Combine

/// Gerencia persistência de contas em accounts.json e credenciais no Keychain
@MainActor
class AppAccountStore: ObservableObject {
    @Published private(set) var accounts: [Account] = []

    private let fileURL: URL
    private let keychainStore = AppKeychainStore()
    private let fileManager = FileManager.default

    enum StoreError: LocalizedError {
        case readError(Error)
        case writeError(Error)
        case accountNotFound(UUID)
        case duplicateAccount(String)

        var errorDescription: String? {
            switch self {
            case .readError(let error):
                return "Erro ao ler contas: \(error.localizedDescription)"
            case .writeError(let error):
                return "Erro ao salvar contas: \(error.localizedDescription)"
            case .accountNotFound(let id):
                return "Conta não encontrada: \(id)"
            case .duplicateAccount(let email):
                return "Conta já existe: \(email)"
            }
        }
    }

    init(fileURL: URL? = nil) {
        if let fileURL = fileURL {
            self.fileURL = fileURL
        } else {
            let appSupport = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!

            let appDir = appSupport.appendingPathComponent("ClaudeUseBar", isDirectory: true)

            // Cria diretório se não existir
            try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)

            self.fileURL = appDir.appendingPathComponent("accounts.json")
        }

        loadAccounts()
    }

    // MARK: - Account Management

    /// Adiciona uma nova conta
    /// - Parameters:
    ///   - oauthAccount: Conta OAuth do Claude
    ///   - credentials: Credenciais da conta
    /// - Returns: Account criado
    /// - Throws: StoreError se a conta já existir
    func addAccount(from oauthAccount: OAuthAccount, credentials: ClaudeCredentials) throws -> Account {
        // Verifica se já existe
        if accounts.contains(where: { $0.emailAddress == oauthAccount.emailAddress }) {
            throw StoreError.duplicateAccount(oauthAccount.emailAddress)
        }

        let account = Account(
            emailAddress: oauthAccount.emailAddress,
            accountUuid: oauthAccount.accountUuid,
            displayName: oauthAccount.displayName,
            organizationName: oauthAccount.organizationName,
            order: accounts.count
        )

        // Salva credenciais no Keychain
        try keychainStore.saveCredentials(credentials, for: account.id)

        // Adiciona à lista
        accounts.append(account)

        // Salva no disco
        try saveAccounts()

        return account
    }

    /// Remove uma conta
    /// - Parameter accountId: ID da conta a remover
    /// - Throws: StoreError se não encontrar a conta
    func removeAccount(_ accountId: UUID) throws {
        guard let index = accounts.firstIndex(where: { $0.id == accountId }) else {
            throw StoreError.accountNotFound(accountId)
        }

        // Remove credenciais do Keychain
        try? keychainStore.deleteCredentials(for: accountId)

        // Remove da lista
        accounts.remove(at: index)

        // Reordena
        for (index, var account) in accounts.enumerated() {
            account.order = index
            accounts[index] = account
        }

        // Salva no disco
        try saveAccounts()
    }

    /// Marca uma conta como usada (atualiza lastUsedAt)
    /// - Parameter accountId: ID da conta
    /// - Throws: StoreError se não encontrar a conta
    func markAsUsed(_ accountId: UUID) throws {
        guard let index = accounts.firstIndex(where: { $0.id == accountId }) else {
            throw StoreError.accountNotFound(accountId)
        }

        var account = accounts[index]
        account.lastUsedAt = Date()
        accounts[index] = account

        try saveAccounts()
    }

    /// Reordena contas
    /// - Parameter newOrder: Nova ordem de IDs
    func reorderAccounts(_ newOrder: [UUID]) throws {
        var reordered: [Account] = []

        for (index, id) in newOrder.enumerated() {
            guard var account = accounts.first(where: { $0.id == id }) else {
                throw StoreError.accountNotFound(id)
            }
            account.order = index
            reordered.append(account)
        }

        accounts = reordered
        try saveAccounts()
    }

    // MARK: - Credentials

    /// Lê credenciais de uma conta
    /// - Parameter accountId: ID da conta
    /// - Returns: ClaudeCredentials
    /// - Throws: KeychainError se não encontrar
    func credentials(for accountId: UUID) throws -> ClaudeCredentials {
        try keychainStore.readCredentials(for: accountId)
    }

    // MARK: - Persistence

    private func loadAccounts() {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            accounts = []
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            accounts = try decoder.decode([Account].self, from: data)
        } catch {
            print("Erro ao carregar contas: \(error)")
            accounts = []
        }
    }

    private func saveAccounts() throws {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            let data = try encoder.encode(accounts)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw StoreError.writeError(error)
        }
    }

    /// Recarrega contas do disco
    func reload() {
        loadAccounts()
    }
}
