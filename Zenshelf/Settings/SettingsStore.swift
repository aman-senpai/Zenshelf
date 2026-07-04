import Foundation

/// User preferences persisted with UserDefaults.
@MainActor
@Observable
final class SettingsStore {
    private enum Keys {
        static let launchAtLogin = "launchAtLogin"
        static let syncAutomatically = "syncAutomatically"
        static let openOnLogin = "openOnLogin"
        static let showDockIcon = "showDockIcon"
    }

    var launchAtLogin: Bool {
        didSet { persistLaunchAtLogin() }
    }

    var syncAutomatically: Bool {
        didSet { userDefaults.set(syncAutomatically, forKey: Keys.syncAutomatically) }
    }

    var openOnLogin: Bool {
        didSet { userDefaults.set(openOnLogin, forKey: Keys.openOnLogin) }
    }

    var showDockIcon: Bool {
        didSet {
            userDefaults.set(showDockIcon, forKey: Keys.showDockIcon)
            dockIconController.apply(showDockIcon: showDockIcon)
        }
    }

    private let userDefaults: UserDefaults
    private let launchAtLoginManager: LaunchAtLoginManager
    private let dockIconController: DockIconController

    init(
        userDefaults: UserDefaults = .standard,
        launchAtLoginManager: LaunchAtLoginManager = LaunchAtLoginManager(),
        dockIconController: DockIconController = DockIconController()
    ) {
        self.userDefaults = userDefaults
        self.launchAtLoginManager = launchAtLoginManager
        self.dockIconController = dockIconController

        launchAtLogin = userDefaults.bool(forKey: Keys.launchAtLogin)
        syncAutomatically = userDefaults.object(forKey: Keys.syncAutomatically) as? Bool ?? true
        openOnLogin = userDefaults.bool(forKey: Keys.openOnLogin)
        showDockIcon = userDefaults.bool(forKey: Keys.showDockIcon)
    }

    /// Applies persisted appearance settings once the application is ready.
    func applyAppearanceSettings() {
        dockIconController.apply(showDockIcon: showDockIcon)
    }

    private func persistLaunchAtLogin() {
        userDefaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
        launchAtLoginManager.setEnabled(launchAtLogin)
    }
}