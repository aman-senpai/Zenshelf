import AppKit
import SwiftUI

/// Presents the onboarding window when Zen Browser is unavailable.
@MainActor
enum OnboardingWindowController {
    private static let windowIdentifier = "zenshelf-onboarding"

    /// Presents onboarding once `NSApplication` has finished launching.
    static func presentIfNeeded(viewModel: AppViewModel) {
        guard viewModel.isOnboardingPresented else { return }

        let present = {
            guard viewModel.isOnboardingPresented else { return }
            presentWindow(viewModel: viewModel)
        }

        if NSApplication.shared.isRunning {
            present()
        } else {
            DispatchQueue.main.async(execute: present)
        }
    }

    static func closeExistingWindow() {
        let close = {
            NSApplication.shared.windows
                .filter { $0.identifier?.rawValue == windowIdentifier }
                .forEach { $0.close() }
        }

        if NSApplication.shared.isRunning {
            close()
        } else {
            DispatchQueue.main.async(execute: close)
        }
    }

    private static func presentWindow(viewModel: AppViewModel) {
        if NSApplication.shared.windows.contains(where: { $0.identifier?.rawValue == windowIdentifier }) {
            return
        }

        NSApplication.shared.activate(ignoringOtherApps: true)

        let hostingController = NSHostingController(
            rootView: OnboardingView(
                onDownload: { viewModel.openZenDownloadPage() },
                onDismiss: {
                    viewModel.isOnboardingPresented = false
                    closeExistingWindow()
                }
            )
        )

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Zen Browser Required"
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.setContentSize(NSSize(width: 380, height: 320))
        window.center()
        window.identifier = NSUserInterfaceItemIdentifier(windowIdentifier)
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
    }
}