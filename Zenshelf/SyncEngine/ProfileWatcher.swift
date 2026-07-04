import Dispatch
import Foundation
import OSLog

/// Watches Zen Browser profile files for changes using kernel file system events.
nonisolated final class ProfileWatcher: @unchecked Sendable {
    typealias ChangeHandler = @Sendable () -> Void

    private let fileManager: FileManager
    private var sources: [DispatchSourceFileSystemObject] = []
    private var watchedDescriptors: [Int32] = []
    private let queue = DispatchQueue(label: "com.senpai.Zenshelf.profile-watcher", qos: .utility)
    private var changeHandler: ChangeHandler?
    private var debounceWorkItem: DispatchWorkItem?

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    deinit {
        stop()
    }

    /// Begins watching the Zen profile directory and session store for modifications.
    func start(profileDirectory: URL, changeHandler: @escaping ChangeHandler) {
        stop()
        self.changeHandler = changeHandler

        let watchedPaths = watchedFileURLs(in: profileDirectory)
        for url in watchedPaths where fileManager.fileExists(atPath: url.path) {
            addSource(for: url)
        }

        AppLogger.sync.debug("Watching \(watchedPaths.count, privacy: .public) Zen profile paths")
    }

    func stop() {
        debounceWorkItem?.cancel()
        debounceWorkItem = nil

        for source in sources {
            source.cancel()
        }
        sources.removeAll()

        for descriptor in watchedDescriptors {
            close(descriptor)
        }
        watchedDescriptors.removeAll()
    }

    private func watchedFileURLs(in profileDirectory: URL) -> [URL] {
        [
            profileDirectory.appendingPathComponent("zen-sessions.jsonlz4")
        ]
    }

    private func addSource(for url: URL) {
        let descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else { return }
        watchedDescriptors.append(descriptor)

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .rename, .delete, .attrib],
            queue: queue
        )

        source.setEventHandler { [weak self] in
            self?.scheduleChangeNotification()
        }

        source.setCancelHandler {
            close(descriptor)
        }

        source.resume()
        sources.append(source)
    }

    private func scheduleChangeNotification() {
        debounceWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.changeHandler?()
        }
        debounceWorkItem = workItem
        queue.asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }
}