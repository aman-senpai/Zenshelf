import AppKit
import SwiftUI

@main
struct ZenshelfApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var viewModel = AppDependencies.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarRootView(viewModel: viewModel)
        } label: {
            Image("MenuBarIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            PreferencesView(settings: viewModel.settings)
        }
    }

    init() {
        AppDependencies.shared.start()
    }
}