import AppKit
import OSLog

/// Handles application lifecycle events that require a fully initialized `NSApplication`.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppLogger.app.info("ZenShelf launched (Compression decoder)")

        Task { @MainActor in
            let viewModel = AppDependencies.shared
            viewModel.settings.applyAppearanceSettings()
            viewModel.evaluateOnboarding()
        }
    }
}