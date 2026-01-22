import Foundation

/// Formata tempo restante até reset
enum TimeFormatter {
    /// Formata tempo restante até uma data
    /// - Parameter date: Data alvo
    /// - Returns: String formatada (ex: "Reseta em 3h 50m")
    static func formatTimeRemaining(until date: Date) -> String {
        let now = Date()
        let interval = date.timeIntervalSince(now)

        // Já passou
        if interval <= 0 {
            return "Resetado"
        }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            if minutes > 0 {
                return "Reseta em \(hours)h \(minutes)m"
            } else {
                return "Reseta em \(hours)h"
            }
        } else if minutes > 0 {
            return "Reseta em \(minutes)m"
        } else {
            let seconds = Int(interval) % 60
            return "Reseta em \(seconds)s"
        }
    }

    /// Formata porcentagem de utilização
    /// - Parameter utilization: Valor de 0 a 1
    /// - Returns: String formatada (ex: "85%")
    static func formatUtilization(_ utilization: Double) -> String {
        let percentage = Int(utilization * 100)
        return "\(percentage)%"
    }

    /// Formata data/hora para exibição
    /// - Parameter date: Data a formatar
    /// - Returns: String formatada (ex: "22/01/2026 15:30")
    static func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Formata tempo relativo (ex: "há 5 minutos")
    /// - Parameter date: Data a formatar
    /// - Returns: String formatada
    static func formatRelative(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
