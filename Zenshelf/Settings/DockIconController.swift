import AppKit

/// Controls whether ZenShelf appears in the Dock.
struct DockIconController: Sendable {
    func apply(showDockIcon: Bool) {
        let policy: NSApplication.ActivationPolicy = showDockIcon ? .regular : .accessory
        DispatchQueue.main.async {
            NSApplication.shared.setActivationPolicy(policy)
        }
    }
}