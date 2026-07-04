import Foundation

/// Describes a detected Zen Browser installation and active profile.
struct ZenInstallation: Sendable, Equatable {
    let applicationURL: URL
    let applicationSupportURL: URL
    let profile: ZenProfile
}

/// A Zen Browser user profile discovered from `profiles.ini`.
struct ZenProfile: Sendable, Equatable {
    let name: String
    let directoryURL: URL
    let isDefault: Bool
}

/// Application state derived from Zen Browser availability.
enum ZenAvailability: Equatable, Sendable {
    case unavailable
    case available(ZenInstallation)
}