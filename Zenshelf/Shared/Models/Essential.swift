import Foundation

/// A pinned Zen Browser Essential surfaced in the menu bar.
struct Essential: Identifiable, Hashable, Sendable {
    /// Stable identifier from Zen's `zenSyncId`.
    let id: String
    let title: String
    /// Canonical URL from the Essential's pinned initial state.
    let url: URL
    let order: Int
    /// One-based index matching Zen's ⌘1–⌘9 shortcuts in session-store tab order.
    let selectionIndex: Int
    let workspaceIdentifier: String?
    let faviconData: Data?

    /// Display title trimmed for menu presentation.
    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return url.host ?? url.absoluteString
        }
        return trimmed
    }
}