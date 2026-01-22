import Foundation

/// Cliente HTTP para a API de usage do Anthropic
actor AnthropicUsageClient {
    private static let baseURL = "https://api.anthropic.com"
    private static let usageEndpoint = "/api/oauth/usage"
    private static let betaVersion = "oauth-2025-04-20"

    private let session: URLSession

    enum ClientError: LocalizedError {
        case invalidURL
        case networkError(Error)
        case invalidToken
        case rateLimited
        case unexpectedStatusCode(Int)
        case decodingError(Error)

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "URL inválida"
            case .networkError(let error):
                return "Erro de rede: \(error.localizedDescription)"
            case .invalidToken:
                return "Token inválido ou expirado"
            case .rateLimited:
                return "Muitas requisições. Tente novamente em alguns minutos."
            case .unexpectedStatusCode(let code):
                return "Código de status inesperado: \(code)"
            case .decodingError(let error):
                return "Erro ao decodificar resposta: \(error.localizedDescription)"
            }
        }
    }

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Busca dados de uso para um access token
    /// - Parameter accessToken: Access token OAuth
    /// - Returns: UsageResponse com dados de uso
    /// - Throws: ClientError em caso de erro
    func fetchUsage(accessToken: String) async throws -> UsageResponse {
        guard let url = URL(string: Self.baseURL + Self.usageEndpoint) else {
            throw ClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(Self.betaVersion, forHTTPHeaderField: "anthropic-beta")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response): (Data, URLResponse)

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ClientError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClientError.networkError(NSError(
                domain: "AnthropicUsageClient",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Resposta inválida do servidor"]
            ))
        }

        switch httpResponse.statusCode {
        case 200:
            return try decodeUsageResponse(from: data)
        case 401:
            throw ClientError.invalidToken
        case 429:
            throw ClientError.rateLimited
        default:
            throw ClientError.unexpectedStatusCode(httpResponse.statusCode)
        }
    }

    // MARK: - Private Helpers

    private func decodeUsageResponse(from data: Data) throws -> UsageResponse {
        let decoder = JSONDecoder()

        // Configura decodificação de datas ISO 8601
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            if let date = formatter.date(from: dateString) {
                return date
            }

            // Fallback sem segundos fracionários
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Data inválida: \(dateString)"
            )
        }

        do {
            return try decoder.decode(UsageResponse.self, from: data)
        } catch {
            throw ClientError.decodingError(error)
        }
    }
}
