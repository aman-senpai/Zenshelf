import AppKit
import ApplicationServices
import CoreGraphics
import Foundation
import OSLog

/// Selects Zen Browser Essentials using keyboard shortcuts (⌘1–⌘9).
/// Requires Accessibility permission to post events to other processes.
enum EssentialSelector {
    private static let bundleIdentifiers = [
        "app.zen-browser.zen",
        "org.mozilla.zen"
    ]

    private static let digitKeyCodes: [Int: CGKeyCode] = [
        1: 18, 2: 19, 3: 20, 4: 21, 5: 23,
        6: 22, 7: 26, 8: 28, 9: 25
    ]

    /// Whether this process can post keyboard events to other apps.
    nonisolated static var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Activates Zen and sends ⌘N to select the nth Essential tab.
    @MainActor
    static func selectEssential(
        at selectionIndex: Int,
        installation: ZenInstallation,
        completion: (@Sendable (Bool) -> Void)? = nil
    ) {
        guard let keyCode = digitKeyCodes[selectionIndex] else {
            AppLogger.browser.error("Essential index \(selectionIndex, privacy: .public) is outside ⌘1–⌘9")
            completion?(false)
            return
        }

        guard isAccessibilityTrusted else {
            AppLogger.browser.error(
                "Accessibility permission required – grant in System Settings > Privacy & Security > Accessibility"
            )
            promptForAccessibility()
            completion?(false)
            return
        }

        activateZen(installation: installation) { application in
            guard let application else {
                completion?(false)
                return
            }

            // Hide self so Zen receives the shortcut, not us.
            NSApp.hide(nil)

            // Cold-launch delay: NSWorkspace.openApplication completes when the
            // process starts, but Zen's Firefox-based UI needs extra time to
            // render its window before it can receive keyboard events.
            let shortcutDelay: TimeInterval = 1.5

            DispatchQueue.main.asyncAfter(deadline: .now() + shortcutDelay) {
                postCommandDigit(keyCode: keyCode, to: application)
                AppLogger.browser.debug(
                    "Sent ⌘\(selectionIndex, privacy: .public) to Zen (PID \(application.processIdentifier))"
                )
                completion?(true)
            }
        }
    }

    /// Shows the system accessibility prompt.
    private static func promptForAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    @MainActor
    private static func activateZen(
        installation: ZenInstallation,
        completion: @escaping @Sendable (NSRunningApplication?) -> Void
    ) {
        if let runningApplication = runningZenApplication() {
            runningApplication.activate(options: [.activateIgnoringOtherApps, .activateAllWindows])
            completion(runningApplication)
            return
        }

        var configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        NSWorkspace.shared.openApplication(
            at: installation.applicationURL,
            configuration: configuration
        ) { runningApplication, error in
            if let error {
                AppLogger.browser.error(
                    "Failed to activate Zen: \(error.localizedDescription, privacy: .public)"
                )
                completion(nil)
                return
            }

            runningApplication?.activate(options: [.activateIgnoringOtherApps, .activateAllWindows])
            completion(runningApplication)
        }
    }

    private static func runningZenApplication() -> NSRunningApplication? {
        for identifier in bundleIdentifiers {
            if let app = NSRunningApplication.runningApplications(withBundleIdentifier: identifier).first {
                return app
            }
        }
        return nil
    }

    private static func postCommandDigit(keyCode: CGKeyCode, to application: NSRunningApplication) {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }

        let pid = application.processIdentifier

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.postToPid(pid)
        keyUp.postToPid(pid)
    }
}
