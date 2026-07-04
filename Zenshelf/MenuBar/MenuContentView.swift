import SwiftUI

/// Primary menu bar dropdown content using native menu conventions.
struct MenuContentView: View {
    @Environment(\.openSettings) private var openSettings
    @Bindable var viewModel: AppViewModel

    var body: some View {
        Group {
            switch viewModel.syncEngine.availability {
            case .unavailable:
                unavailableMenu
            case .available:
                availableMenu
            }
        }
        .onAppear {
            viewModel.evaluateOnboarding()
        }
        .onChange(of: viewModel.syncEngine.availability) {
            viewModel.evaluateOnboarding()
        }
    }

    @ViewBuilder
    private var availableMenu: some View {
        Section {
            ForEach(viewModel.syncEngine.essentials) { essential in
                Button {
                    viewModel.openEssential(essential)
                } label: {
                    EssentialLabel(
                        essential: essential,
                        faviconData: viewModel.favicon(for: essential)
                    )
                }
                .accessibilityLabel(essential.displayTitle)
                .accessibilityHint("Opens this Essential in Zen Browser")
            }

            if viewModel.syncEngine.essentials.isEmpty {
                Text("No Essentials found")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("No Essentials found in Zen Browser")
            }
        } header: {
            Text("Pinned Essentials")
        }

        Divider()

        Button("Refresh") {
            viewModel.forceRefresh()
        }
        .keyboardShortcut("r", modifiers: [.command])

        Button("Open Zen") {
            viewModel.openZenBrowser()
        }
        .keyboardShortcut("o", modifiers: [.command])

        Divider()

        Button("Preferences…") {
            openSettings()
        }
        .keyboardShortcut(",", modifiers: [.command])

        Button("Quit ZenShelf") {
            viewModel.quit()
        }
        .keyboardShortcut("q", modifiers: [.command])
    }

    @ViewBuilder
    private var unavailableMenu: some View {
        Text("Install Zen Browser to sync Essentials.")
            .foregroundStyle(.secondary)
            .accessibilityLabel("Install Zen Browser to sync Essentials")

        Divider()

        Button("Get Zen Browser") {
            viewModel.openZenDownloadPage()
        }

        Button("Refresh") {
            viewModel.forceRefresh()
        }

        Divider()

        Button("Preferences…") {
            openSettings()
        }
        .keyboardShortcut(",", modifiers: [.command])

        Button("Quit ZenShelf") {
            viewModel.quit()
        }
        .keyboardShortcut("q", modifiers: [.command])
    }
}

/// Native menu label pairing favicon and title.
private struct EssentialLabel: View {
    let essential: Essential
    let faviconData: Data?

    var body: some View {
        Label {
            Text(essential.displayTitle)
                .lineLimit(1)
        } icon: {
            FaviconView(data: faviconData, title: essential.displayTitle)
        }
    }
}