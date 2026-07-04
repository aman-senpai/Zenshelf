import AppKit
import Foundation

/// Primary application view model coordinating sync, settings, and browser actions.
@MainActor
@Observable
final class AppViewModel {
    let syncEngine: SyncEngine
    let settings: SettingsStore
    private let launcher = ZenBrowserLauncher()

    var isOnboardingPresented = false

    init(
        settings: SettingsStore = SettingsStore()
    ) {
        self.settings = settings
        self.syncEngine = SyncEngine { [settings] in
            settings.syncAutomatically
        }
    }

    func start() {
        syncEngine.start()
    }

    func refresh() {
        guard settings.syncAutomatically else { return }
        syncEngine.refresh()
    }

    func forceRefresh() {
        syncEngine.refresh()
        evaluateOnboarding()
    }

    func openEssential(_ essential: Essential) {
        guard case let .available(installation) = syncEngine.availability else { return }
        launcher.open(essential: essential, installation: installation)
    }

    func openZenBrowser() {
        guard case let .available(installation) = syncEngine.availability else { return }
        launcher.activate(installation: installation)
    }

    func openZenDownloadPage() {
        guard let url = URL(string: "https://zen-browser.app/download") else { return }
        NSWorkspace.shared.open(url)
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }

    func evaluateOnboarding() {
        isOnboardingPresented = syncEngine.availability == .unavailable

        if isOnboardingPresented {
            OnboardingWindowController.presentIfNeeded(viewModel: self)
        } else {
            OnboardingWindowController.closeExistingWindow()
        }
    }

    func favicon(for essential: Essential) -> Data? {
        syncEngine.favicon(for: essential)
    }
}