import Foundation
import Security

/// Gerencia credenciais das contas do app no Keychain
struct AppKeychainStore {
    private static let servicePrefix = "com.joaoalves.claudeusebar.account"

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
                return "Credenciais não encontradas no Keychain"
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

    /// Salva credenciais para uma conta
    /// - Parameters:
    ///   - credentials: Credenciais a serem salvas
    ///   - accountId: ID da conta
    /// - Throws: KeychainError em caso de erro
    func saveCredentials(_ credentials: ClaudeCredentials, for accountId: UUID) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(credentials)
        try saveData(data, for: accountId)
    }

    /// Lê credenciais para uma conta
    /// - Parameter accountId: ID da conta
    /// - Returns: ClaudeCredentials decodificado
    /// - Throws: KeychainError em caso de erro
    func readCredentials(for accountId: UUID) throws -> ClaudeCredentials {
        let data = try readData(for: accountId)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(ClaudeCredentials.self, from: data)
        } catch {
            throw KeychainError.parseError(error)
        }
    }

    /// Deleta credenciais para uma conta
    /// - Parameter accountId: ID da conta
    /// - Throws: KeychainError em caso de erro
    func deleteCredentials(for accountId: UUID) throws {
        let service = Self.servicePrefix + ".\(accountId.uuidString)"

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteError(status)
        }
    }

    // MARK: - Private Helpers

    private func saveData(_ data: Data, for accountId: UUID) throws {
        let service = Self.servicePrefix + ".\(accountId.uuidString)"

        // Primeiro tenta atualizar
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accountId.uuidString
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

    private func readData(for accountId: UUID) throws -> Data {
        let service = Self.servicePrefix + ".\(accountId.uuidString)"

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accountId.uuidString,
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
}
