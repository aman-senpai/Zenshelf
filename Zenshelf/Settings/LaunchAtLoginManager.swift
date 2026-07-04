import Foundation
import OSLog
import ServiceManagement

/// Manages Launch at Login using SMAppService.
nonisolated struct LaunchAtLoginManager: Sendable {
    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
                AppLogger.app.info("Registered Launch at Login")
            } else {
                try SMAppService.mainApp.unregister()
                AppLogger.app.info("Unregistered Launch at Login")
            }
        } catch {
            AppLogger.errors.error("Launch at Login update failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}