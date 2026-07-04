import Foundation

/// Synchronization state exposed to the menu bar interface.
enum SyncState: Equatable, Sendable {
    case idle
    case syncing
    case failed(message: String)
}