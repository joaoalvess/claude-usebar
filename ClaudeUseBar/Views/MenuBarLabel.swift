import SwiftUI

/// Label exibido na status bar
struct MenuBarLabel: View {
    @EnvironmentObject var usageViewModel: UsageViewModel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 14))

            Text(usageViewModel.statusBarText)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
        }
    }
}
