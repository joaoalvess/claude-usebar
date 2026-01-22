import Foundation

/// Representa as credenciais armazenadas no Keychain do Claude Code
struct ClaudeCredentials: Codable, Equatable {
    let claudeAiOauth: ClaudeAiOAuth

    struct ClaudeAiOAuth: Codable, Equatable {
        let accessToken: String
        let refreshToken: String?
        let expiresAt: Date?
        let tokenType: String?

        enum CodingKeys: String, CodingKey {
            case accessToken
            case refreshToken
            case expiresAt
            case tokenType
        }
    }

    enum CodingKeys: String, CodingKey {
        case claudeAiOauth
    }

    /// Acesso rápido ao access token
    var accessToken: String {
        claudeAiOauth.accessToken
    }

    init(accessToken: String, refreshToken: String? = nil, expiresAt: Date? = nil, tokenType: String? = nil) {
        self.claudeAiOauth = ClaudeAiOAuth(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt,
            tokenType: tokenType
        )
    }
}
