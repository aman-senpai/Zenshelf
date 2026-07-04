import AppKit
import Foundation
import OSLog

/// Activates Zen Browser and selects Essentials without opening new tabs.
@MainActor
struct ZenBrowserLauncher {
    /// Brings Zen Browser to the foreground.
    func activate(installation: ZenInstallation) {
        if let runningApplication = NSRunningApplication.runningApplications(
            withBundleIdentifier: "app.zen-browser.zen"
        ).first ?? NSRunningApplication.runningApplications(
            withBundleIdentifier: "org.mozilla.zen"
        ).first {
            runningApplication.activate(options: [.activateIgnoringOtherApps, .activateAllWindows])
            return
        }

        var configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(
            at: installation.applicationURL,
            configuration: configuration
        ) { _, error in
            if let error {
                AppLogger.browser.error(
                    "Failed to activate Zen: \(error.localizedDescription, privacy: .public)"
                )
            }
        }
    }

    /// Selects an existing Essential in Zen Browser.
    func open(essential: Essential, installation: ZenInstallation) {
        EssentialSelector.selectEssential(
            at: essential.selectionIndex,
            installation: installation
        ) { success in
            if !success && !EssentialSelector.isAccessibilityTrusted {
                Task { @MainActor in
                    showAccessibilityAlert()
                }
            }
        }
    }

    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "ZenShelf needs Accessibility permission to switch to Essentials in Zen Browser.\n\nGrant it in System Settings → Privacy & Security → Accessibility, then restart ZenShelf."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "OK")

        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }
}