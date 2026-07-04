import Foundation

/// Dependency container for the ZenShelf application.
@MainActor
enum AppDependencies {
    static let shared = AppViewModel()
}