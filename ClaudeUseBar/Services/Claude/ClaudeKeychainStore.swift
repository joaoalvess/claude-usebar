import Foundation
import Security

/// Gerencia credenciais do Claude Code armazenadas no Keychain do macOS
struct ClaudeKeychainStore {
    private static let service = "Claude Code-credentials"

    enum KeychainError: LocalizedError {
        case itemNotFound
        case readError(OSStatus)
        case writeError(OSStatus)
        case deleteError(OSStatus)
        case invalidData
        case parseError(Error)

        var errorDescription: String? {
            switch self {
            case .itemNotFound:
                return "Credenciais do Claude Code não encontradas no Keychain"
            case .readError(let status):
                return "Erro ao ler do Keychain: \(status)"
            case .writeError(let status):
                return "Erro ao escrever no Keychain: \(status)"
            case .deleteError(let status):
                return "Erro ao deletar do Keychain: \(status)"
            case .invalidData:
                return "Dados inválidos no Keychain"
            case .parseError(let error):
                return "Erro ao decodificar credenciais: \(error.localizedDescription)"
            }
        }
    }

    private let account: String

    init(account: String = ClaudeInstall.username) {
        self.account = account
    }

    /// Lê as credenciais do Keychain do Claude Code
    /// - Returns: ClaudeCredentials decodificado
    /// - Throws: KeychainError em caso de erro
    func readCredentials() throws -> ClaudeCredentials {
        let data = try readCredentialsData()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(ClaudeCredentials.self, from: data)
        } catch {
            throw KeychainError.parseError(error)
        }
    }

    /// Escreve credenciais no Keychain do Claude Code
    /// - Parameter credentials: Credenciais a serem escritas
    /// - Throws: KeychainError em caso de erro
    func writeCredentials(_ credentials: ClaudeCredentials) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(credentials)
        try writeCredentialsData(data)
    }

    /// Lê os dados brutos do Keychain
    /// - Returns: Dados brutos das credenciais
    /// - Throws: KeychainError em caso de erro
    func readCredentialsData() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.readError(status)
        }

        guard let data = item as? Data else {
            throw KeychainError.invalidData
        }

        return data
    }

    /// Escreve dados brutos no Keychain
    /// - Parameter data: Dados a serem escritos
    /// - Throws: KeychainError em caso de erro
    func writeCredentialsData(_ data: Data) throws {
        // Primeiro tenta atualizar
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        // Se não existir, cria novo
        if status == errSecItemNotFound {
            var newItem = query
            newItem[kSecValueData as String] = data

            status = SecItemAdd(newItem as CFDictionary, nil)
        }

        guard status == errSecSuccess else {
            throw KeychainError.writeError(status)
        }
    }

    /// Restaura credenciais a partir de um backup
    /// - Parameter backupData: Dados de backup
    /// - Throws: KeychainError em caso de erro
    func restoreCredentials(from backupData: Data) throws {
        try writeCredentialsData(backupData)
    }

    /// Deleta as credenciais do Keychain
    /// - Throws: KeychainError em caso de erro
    func deleteCredentials() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteError(status)
        }
    }
}
