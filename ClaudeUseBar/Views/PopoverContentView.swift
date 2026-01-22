import SwiftUI

/// Container principal do popover
struct PopoverContentView: View {
    @EnvironmentObject var accountStore: AppAccountStore
    @EnvironmentObject var usageViewModel: UsageViewModel

    @State private var showingAddAccount = false
    @State private var showingSwitchAlert = false
    @State private var switchAlertMessage = ""
    @State private var accountToActivate: Account?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Lista de contas
            ScrollView {
                VStack(spacing: 12) {
                    if usageViewModel.accountUsages.isEmpty {
                        emptyState
                    } else {
                        ForEach(usageViewModel.accountUsages) { accountUsage in
                            AccountRowView(
                                accountUsage: accountUsage,
                                isActive: accountUsage.account.accountUuid == usageViewModel.activeAccountUuid,
                                onActivate: {
                                    handleActivate(account: accountUsage.account)
                                },
                                onRemove: {
                                    handleRemove(account: accountUsage.account)
                                }
                            )
                        }
                    }
                }
                .padding(12)
            }
            .frame(maxHeight: 400)

            Divider()

            // Footer
            footer
        }
        .frame(width: 360)
        .background(backgroundMaterial)
        .sheet(isPresented: $showingAddAccount) {
            AddAccountView(accountStore: accountStore)
        }
        .alert("Conta Trocada", isPresented: $showingSwitchAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(switchAlertMessage)
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            Text("Claude UseBar")
                .font(.headline)

            Spacer()

            Button(action: handleRefresh) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14))
                    .rotationEffect(.degrees(usageViewModel.isRefreshing ? 360 : 0))
                    .animation(
                        usageViewModel.isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                        value: usageViewModel.isRefreshing
                    )
            }
            .buttonStyle(.plain)
            .help("Atualizar")
            .disabled(usageViewModel.isRefreshing)

            Button(action: { NSApplication.shared.terminate(nil) }) {
                Image(systemName: "power")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .help("Sair")
        }
        .padding(12)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("Nenhuma conta adicionada")
                .font(.headline)

            Text("Clique no botão abaixo para adicionar sua primeira conta do Claude Code.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(40)
    }

    private var footer: some View {
        Button(action: { showingAddAccount = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Adicionar Conta")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .padding(12)
    }

    @ViewBuilder
    private var backgroundMaterial: some View {
        if #available(macOS 26.0, *) {
            // Liquid Glass nativo no macOS 26+
            // Por enquanto usamos material até termos o framework atualizado
            Color(nsColor: .controlBackgroundColor)
        } else {
            // Fallback para versões anteriores
            Color(nsColor: .controlBackgroundColor)
        }
    }

    // MARK: - Actions

    private func handleRefresh() {
        Task {
            await usageViewModel.refreshAll()
        }
    }

    private func handleActivate(account: Account) {
        accountToActivate = account

        Task {
            let switcher = AccountSwitcher(accountStore: accountStore)

            do {
                let result = try await switcher.switchTo(account: account)

                await MainActor.run {
                    switchAlertMessage = result.message
                    showingSwitchAlert = true

                    // Recarrega conta ativa
                    usageViewModel.reloadActiveAccount()
                }

            } catch {
                await MainActor.run {
                    switchAlertMessage = "Erro ao trocar conta: \(error.localizedDescription)"
                    showingSwitchAlert = true
                }
            }
        }
    }

    private func handleRemove(account: Account) {
        do {
            try accountStore.removeAccount(account.id)
        } catch {
            print("Erro ao remover conta: \(error)")
        }
    }
}
