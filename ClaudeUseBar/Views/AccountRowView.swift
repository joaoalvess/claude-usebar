import SwiftUI

/// Linha de conta no popover
struct AccountRowView: View {
    let accountUsage: AccountUsage
    let isActive: Bool
    let onActivate: () -> Void
    let onRemove: () -> Void

    @State private var showingRemoveConfirmation = false
    @State private var isActivating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header com nome e badge
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(accountUsage.account.displayName)
                            .font(.system(size: 14, weight: .semibold))

                        if isActive {
                            Text("Ativa")
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.15))
                                .foregroundColor(.accentColor)
                                .cornerRadius(4)
                        }
                    }

                    Text(accountUsage.account.emailAddress)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Botão remover
                Button(action: { showingRemoveConfirmation = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Remover conta")
            }

            // Usage ou estado de erro/loading
            usageContent

            // Botão ativar (se não for ativa)
            if !isActive {
                Button(action: handleActivate) {
                    if isActivating {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Ativando...")
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Text("Ativar")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isActivating)
            }
        }
        .padding(12)
        .background(rowBackground)
        .cornerRadius(8)
        .confirmationDialog(
            "Remover conta?",
            isPresented: $showingRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remover", role: .destructive, action: onRemove)
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Esta ação não pode ser desfeita. As credenciais serão removidas do app.")
        }
    }

    @ViewBuilder
    private var usageContent: some View {
        switch accountUsage.loadingState {
        case .idle, .loading:
            HStack {
                ProgressView()
                    .scaleEffect(0.7)
                Text("Carregando...")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

        case .loaded(let response, _):
            UsageProgressView(response: response)

        case .error(let error):
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)

                Text(error.localizedDescription)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var rowBackground: some View {
        Group {
            if isActive {
                Color.accentColor.opacity(0.08)
            } else {
                Color.secondary.opacity(0.05)
            }
        }
    }

    private func handleActivate() {
        isActivating = true

        Task {
            onActivate()

            // Aguarda um pouco para feedback visual
            try? await Task.sleep(nanoseconds: 500_000_000)

            await MainActor.run {
                isActivating = false
            }
        }
    }
}
