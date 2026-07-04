import Foundation
import OSLog

/// Centralized logging for ZenShelf using OSLog categories.
nonisolated enum AppLogger {
    static let app = Logger(subsystem: subsystem, category: "App")
    static let sync = Logger(subsystem: subsystem, category: "Sync")
    static let browser = Logger(subsystem: subsystem, category: "Browser")
    static let menu = Logger(subsystem: subsystem, category: "Menu")
    static let errors = Logger(subsystem: subsystem, category: "Errors")
    static let debug = Logger(subsystem: subsystem, category: "Debug")

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.senpai.Zenshelf"
}