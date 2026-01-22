import SwiftUI

@main
struct ClaudeUseBarApp: App {
    @StateObject private var accountStore = AppAccountStore()
    @StateObject private var usageViewModel: UsageViewModel

    init() {
        let accountStore = AppAccountStore()
        _accountStore = StateObject(wrappedValue: accountStore)
        _usageViewModel = StateObject(wrappedValue: UsageViewModel(accountStore: accountStore))
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverContentView()
                .environmentObject(accountStore)
                .environmentObject(usageViewModel)
        } label: {
            MenuBarLabel()
                .environmentObject(usageViewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
