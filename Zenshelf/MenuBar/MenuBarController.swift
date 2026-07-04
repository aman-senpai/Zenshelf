import SwiftUI

/// Hosts the menu bar extra and onboarding window.
struct MenuBarRootView: View {
    @Bindable var viewModel: AppViewModel

    var body: some View {
        MenuContentView(viewModel: viewModel)
    }
}