import Foundation
import OSLog

/// Parses Zen Browser Essentials from session store data.
nonisolated struct EssentialParser: Sendable {
    enum ParserError: Error {
        case sessionStoreUnavailable
        case invalidStructure
    }

    private let sessionStoreFileName = "zen-sessions.jsonlz4"

    /// Loads Essentials from the active Zen profile directory.
    func parse(profileDirectory: URL) throws -> [Essential] {
        let sessionStoreURL = profileDirectory.appendingPathComponent(sessionStoreFileName)
        guard FileManager.default.isReadableFile(atPath: sessionStoreURL.path) else {
            throw ParserError.sessionStoreUnavailable
        }

        let dictionary = try JSONLZ4Decoder.decode(contentsOf: sessionStoreURL)
        guard let tabs = dictionary["tabs"] as? [[String: Any]] else {
            throw ParserError.invalidStructure
        }

        // Zen's ⌘1–⌘9 shortcuts follow session-store tab order, not visual grid order.
        var shortcutIndex = 0
        var essentials: [Essential] = []

        for tab in tabs {
            guard var essential = parseEssential(tab: tab) else { continue }
            shortcutIndex += 1
            essential = Essential(
                id: essential.id,
                title: essential.title,
                url: essential.url,
                order: shortcutIndex,
                selectionIndex: shortcutIndex,
                workspaceIdentifier: essential.workspaceIdentifier,
                faviconData: essential.faviconData
            )
            essentials.append(essential)
        }

        AppLogger.sync.info(
            "Parsed \(essentials.count, privacy: .public) Essentials from \(profileDirectory.lastPathComponent, privacy: .public)"
        )
        return essentials
    }

    private func parseEssential(tab: [String: Any]) -> Essential? {
        guard tab["zenEssential"] as? Bool == true else { return nil }
        guard let entries = tab["entries"] as? [[String: Any]], let firstEntry = entries.first else {
            return nil
        }

        let pinnedEntry = pinnedInitialEntry(from: tab) ?? firstEntry
        guard let urlString = pinnedEntry["url"] as? String,
              let url = URL(string: urlString),
              !urlString.isEmpty else {
            return nil
        }

        let syncIdentifier = (tab["zenSyncId"] as? String) ?? url.absoluteString
        let title = (pinnedEntry["title"] as? String) ?? (firstEntry["title"] as? String) ?? ""
        let order = tab["index"] as? Int ?? 0
        let workspaceIdentifier = tab["zenWorkspace"] as? String
        let faviconData = extractFaviconData(from: tab)

        return Essential(
            id: syncIdentifier,
            title: title,
            url: url,
            order: order,
            selectionIndex: 0,
            workspaceIdentifier: workspaceIdentifier,
            faviconData: faviconData
        )
    }

    private func pinnedInitialEntry(from tab: [String: Any]) -> [String: Any]? {
        guard let initialState = tab["_zenPinnedInitialState"] as? [String: Any],
              let entry = initialState["entry"] as? [String: Any] else {
            return nil
        }
        return entry
    }

    private func extractFaviconData(from tab: [String: Any]) -> Data? {
        guard let initialState = tab["_zenPinnedInitialState"] as? [String: Any],
              let imageString = initialState["image"] as? String,
              imageString.hasPrefix("data:"),
              let commaIndex = imageString.firstIndex(of: ",") else {
            return nil
        }

        let base64String = String(imageString[imageString.index(after: commaIndex)...])
        return Data(base64Encoded: base64String)
    }
}