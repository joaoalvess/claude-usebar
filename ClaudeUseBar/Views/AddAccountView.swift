import SwiftUI

/// View para adicionar nova conta
struct AddAccountView: View {
    @EnvironmentObject var accountStore: AppAccountStore
    @StateObject private var viewModel: AddAccountViewModel
    @Environment(\.dismiss) private var dismiss

    init(accountStore: AppAccountStore) {
        _viewModel = StateObject(wrappedValue: AddAccountViewModel(accountStore: accountStore))
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Adicionar Conta")
                    .font(.headline)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Content baseado no estado
            Group {
                switch viewModel.state {
                case .idle:
                    instructionsView

                case .instructions:
                    instructionsView

                case .capturing, .validating:
                    loadingView

                case .success(let account):
                    successView(account: account)

                case .error:
                    errorView
                }
            }
            .frame(maxHeight: .infinity)

            Divider()

            // Footer com botões
            footerButtons
        }
        .padding(20)
        .frame(width: 400, height: 350)
        .onAppear {
            if case .idle = viewModel.state {
                viewModel.showInstructions()
            }
        }
    }

    // MARK: - Subviews

    private var instructionsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text(viewModel.instructionsText)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            if case .capturing = viewModel.state {
                Text("Capturando conta...")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            } else {
                Text("Validando credenciais...")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func successView(account: Account) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)

            Text(viewModel.successMessage(for: account))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text(viewModel.errorMessage ?? "Erro desconhecido")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var footerButtons: some View {
        HStack {
            if case .success = viewModel.state {
                Button("Fechar") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            } else if case .error = viewModel.state {
                Button("Tentar Novamente") {
                    viewModel.reset()
                    viewModel.showInstructions()
                }
                .buttonStyle(.bordered)

                Button("Fechar") {
                    dismiss()
                }
            } else if case .instructions = viewModel.state {
                Button("Cancelar") {
                    dismiss()
                }

                Spacer()

                Button("Capturar Conta Atual") {
                    Task {
                        await viewModel.captureCurrentAccount()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
