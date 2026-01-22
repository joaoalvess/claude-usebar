import Foundation

/// Resposta da API de usage do Anthropic
struct UsageResponse: Codable, Equatable {
    let fiveHour: UsagePeriod
    let sevenDay: UsagePeriod?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
    }

    struct UsagePeriod: Codable, Equatable {
        let utilization: Double
        let resetsAt: Date

        enum CodingKeys: String, CodingKey {
            case utilization
            case resetsAt = "resets_at"
        }

        init(utilization: Double, resetsAt: Date) {
            self.utilization = utilization
            self.resetsAt = resetsAt
        }
    }

    init(fiveHour: UsagePeriod, sevenDay: UsagePeriod? = nil) {
        self.fiveHour = fiveHour
        self.sevenDay = sevenDay
    }

    /// Porcentagem de utilização (0-100)
    var utilizationPercentage: Int {
        Int(fiveHour.utilization * 100)
    }

    /// Data/hora do próximo reset
    var resetsAt: Date {
        fiveHour.resetsAt
    }

    /// Tempo restante até o reset
    var timeUntilReset: TimeInterval {
        resetsAt.timeIntervalSinceNow
    }

    /// Verifica se o limite foi excedido
    var isLimitExceeded: Bool {
        fiveHour.utilization >= 1.0
    }

    /// Verifica se está próximo do limite (>= 80%)
    var isNearLimit: Bool {
        fiveHour.utilization >= 0.8
    }
}
