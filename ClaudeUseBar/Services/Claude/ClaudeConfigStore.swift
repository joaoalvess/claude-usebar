import Foundation

/// Gerencia leitura e escrita do arquivo de configuração do Claude Code
struct ClaudeConfigStore {
    enum ConfigError: LocalizedError {
        case fileNotFound
        case readError(Error)
        case writeError(Error)
        case parseError(Error)
        case missingOAuthAccount
        case invalidJSON

        var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "Arquivo de configuração não encontrado"
            case .readError(let error):
                return "Erro ao ler configuração: \(error.localizedDescription)"
            case .writeError(let error):
                return "Erro ao escrever configuração: \(error.localizedDescription)"
            case .parseError(let error):
                return "Erro ao analisar JSON: \(error.localizedDescription)"
            case .missingOAuthAccount:
                return "Campo oauthAccount não encontrado no arquivo de configuração"
            case .invalidJSON:
                return "JSON inválido no arquivo de configuração"
            }
        }
    }

    private let configURL: URL

    init() throws {
        let (url, _) = try ClaudeInstall.resolveConfigPath()
        self.configURL = url
    }

    init(configURL: URL) {
        self.configURL = configURL
    }

    /// Lê a conta OAuth do arquivo de configuração
    /// - Returns: OAuthAccount encontrado
    /// - Throws: ConfigError em caso de erro
    func readOAuthAccount() throws -> OAuthAccount {
        let data = try readConfigData()

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ConfigError.invalidJSON
        }

        guard let oauthAccountDict = json["oauthAccount"] as? [String: Any] else {
            throw ConfigError.missingOAuthAccount
        }

        let oauthAccountData = try JSONSerialization.data(withJSONObject: oauthAccountDict)

        let decoder = JSONDecoder()
        do {
            return try decoder.decode(OAuthAccount.self, from: oauthAccountData)
        } catch {
            throw ConfigError.parseError(error)
        }
    }

    /// Escreve a conta OAuth no arquivo de configuração
    /// Preserva todos os outros campos do JSON
    /// - Parameter account: Conta OAuth a ser escrita
    /// - Throws: ConfigError em caso de erro
    func writeOAuthAccount(_ account: OAuthAccount) throws {
        let data = try readConfigData()

        guard var json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ConfigError.invalidJSON
        }

        let encoder = JSONEncoder()
        let accountData = try encoder.encode(account)

        guard let accountDict = try JSONSerialization.jsonObject(with: accountData) as? [String: Any] else {
            throw ConfigError.invalidJSON
        }

        json["oauthAccount"] = accountDict

        let updatedData = try JSONSerialization.data(
            withJSONObject: json,
            options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        )

        try writeConfigData(updatedData)
    }

    /// Lê os dados brutos do arquivo de configuração
    /// - Returns: Dados do arquivo
    /// - Throws: ConfigError em caso de erro
    func readConfigData() throws -> Data {
        do {
            return try Data(contentsOf: configURL)
        } catch {
            throw ConfigError.readError(error)
        }
    }

    /// Escreve dados brutos no arquivo de configuração
    /// - Parameter data: Dados a serem escritos
    /// - Throws: ConfigError em caso de erro
    func writeConfigData(_ data: Data) throws {
        do {
            try data.write(to: configURL, options: .atomic)
        } catch {
            throw ConfigError.writeError(error)
        }
    }

    /// Restaura o arquivo de configuração a partir de um backup
    /// - Parameter backupData: Dados de backup
    /// - Throws: ConfigError em caso de erro
    func restoreConfig(from backupData: Data) throws {
        try writeConfigData(backupData)
    }
}
