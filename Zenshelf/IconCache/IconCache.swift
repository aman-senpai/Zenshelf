import Foundation

/// In-memory favicon cache keyed by Essential identifier.
nonisolated final class IconCache: @unchecked Sendable {
    private var storage: [String: Data] = [:]
    private let lock = NSLock()

    /// Returns cached favicon data for an Essential.
    func favicon(for essential: Essential) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return storage[essential.id] ?? essential.faviconData
    }

    /// Stores favicons from freshly synchronized Essentials.
    func store(essentials: [Essential]) {
        lock.lock()
        defer { lock.unlock() }

        for essential in essentials {
            if let data = essential.faviconData {
                storage[essential.id] = data
            }
        }
    }

    /// Removes all cached favicons.
    func clear() {
        lock.lock()
        defer { lock.unlock() }
        storage.removeAll()
    }
}