import SwiftUI

/// Barra de progresso de utilização
struct UsageProgressView: View {
    let response: UsageResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(TimeFormatter.formatUtilization(response.fiveHour.utilization))
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(utilizationColor)

                Spacer()

                Text(TimeFormatter.formatTimeRemaining(until: response.resetsAt))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            ProgressView(value: response.fiveHour.utilization, total: 1.0)
                .tint(utilizationColor)
                .frame(height: 6)
        }
    }

    private var utilizationColor: Color {
        let utilization = response.fiveHour.utilization

        if utilization >= 1.0 {
            return .red
        } else if utilization >= 0.8 {
            return .orange
        } else if utilization >= 0.6 {
            return .yellow
        } else {
            return .green
        }
    }
}
