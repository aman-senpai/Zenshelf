import Foundation
import OSLog

/// Orchestrates Zen Browser detection, Essentials parsing, and live synchronization.
@MainActor
@Observable
final class SyncEngine {
    private(set) var availability: ZenAvailability = .unavailable
    private(set) var essentials: [Essential] = []
    private(set) var syncState: SyncState = .idle

    private let detector: ZenBrowserDetector
    private let parser: EssentialParser
    private let watcher: ProfileWatcher
    private let iconCache: IconCache
    private let shouldSyncAutomatically: @MainActor () -> Bool
    private var isStarted = false
    private var isReloading = false

    init(
        detector: ZenBrowserDetector = ZenBrowserDetector(),
        parser: EssentialParser = EssentialParser(),
        watcher: ProfileWatcher = ProfileWatcher(),
        iconCache: IconCache = IconCache(),
        shouldSyncAutomatically: @escaping @MainActor () -> Bool = { true }
    ) {
        self.detector = detector
        self.parser = parser
        self.watcher = watcher
        self.iconCache = iconCache
        self.shouldSyncAutomatically = shouldSyncAutomatically
    }

    /// Starts detection and continuous synchronization.
    func start() {
        guard !isStarted else { return }
        isStarted = true
        refreshAvailability()
    }

    /// Stops filesystem observation.
    func stop() {
        watcher.stop()
        isStarted = false
    }

    /// Re-detects Zen Browser and reloads Essentials.
    func refresh() {
        refreshAvailability(forceReload: true)
    }

    /// Returns a cached favicon for the given Essential.
    func favicon(for essential: Essential) -> Data? {
        iconCache.favicon(for: essential)
    }

    private func refreshAvailability(forceReload: Bool = false) {
        let detected = detector.detect()
        let profileChanged: Bool = {
            switch (availability, detected) {
            case let (.available(previous), .available(current)):
                return previous.profile.directoryURL != current.profile.directoryURL
            case (.unavailable, .available), (.available, .unavailable):
                return true
            default:
                return false
            }
        }()

        availability = detected

        switch detected {
        case .unavailable:
            essentials = []
            syncState = .idle
            watcher.stop()
        case let .available(installation):
            if forceReload || profileChanged || essentials.isEmpty {
                reloadEssentials(from: installation.profile.directoryURL)
            }
            configureWatcher(for: installation.profile.directoryURL)
        }
    }

    private func configureWatcher(for profileDirectory: URL) {
        watcher.start(profileDirectory: profileDirectory) { [weak self] in
            Task { @MainActor in
                guard let self, self.shouldSyncAutomatically() else { return }
                self.reloadEssentials(from: profileDirectory)
            }
        }
    }

    private func reloadEssentials(from profileDirectory: URL) {
        guard !isReloading else { return }
        isReloading = true
        syncState = .syncing

        Task {
            defer {
                Task { @MainActor in
                    self.isReloading = false
                }
            }

            do {
                let parsed = try parser.parse(profileDirectory: profileDirectory)
                await MainActor.run {
                    self.essentials = parsed
                    self.syncState = .idle
                    self.iconCache.store(essentials: parsed)
                    AppLogger.sync.info("Synchronized \(parsed.count, privacy: .public) Essentials")
                }
            } catch {
                await MainActor.run {
                    if self.essentials.isEmpty {
                        self.syncState = .failed(message: "Unable to read Essentials")
                    } else {
                        self.syncState = .idle
                    }
                    AppLogger.errors.error("Essentials sync failed: \(String(describing: error), privacy: .public)")
                }
            }
        }
    }
}