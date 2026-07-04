import AppKit
import Foundation
import OSLog

/// Detects Zen Browser installations and resolves the active user profile.
struct ZenBrowserDetector: Sendable {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Returns the current Zen Browser availability state.
    func detect() -> ZenAvailability {
        guard let applicationURL = locateApplication() else {
            AppLogger.browser.info("Zen Browser application not found")
            return .unavailable
        }

        let zenSupportURL = zenApplicationSupportURL()
        guard fileManager.isReadableFile(atPath: zenSupportURL.path) else {
            AppLogger.browser.info(
                "Zen Browser support directory not found at \(zenSupportURL.path, privacy: .public)"
            )
            return .unavailable
        }

        guard let profile = resolveDefaultProfile(in: zenSupportURL) else {
            AppLogger.browser.error("Unable to resolve Zen Browser profile")
            return .unavailable
        }

        let installation = ZenInstallation(
            applicationURL: applicationURL,
            applicationSupportURL: zenSupportURL,
            profile: profile
        )
        AppLogger.browser.info("Zen Browser detected at \(applicationURL.path, privacy: .public)")
        return .available(installation)
    }

    /// Real user-level Zen data directory (outside the app sandbox container).
    private func zenApplicationSupportURL() -> URL {
        RealUserHome.applicationSupportURL
            .appendingPathComponent("zen", isDirectory: true)
    }

    private func locateApplication() -> URL? {
        let bundleIdentifiers = [
            "app.zen-browser.zen",
            "org.mozilla.zen"
        ]

        for identifier in bundleIdentifiers {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier) {
                return url
            }
        }

        let candidatePaths = [
            "/Applications/Zen.app",
            URL(fileURLWithPath: RealUserHome.path, isDirectory: true)
                .appendingPathComponent("Applications/Zen.app")
                .path
        ]

        for path in candidatePaths {
            if fileManager.isReadableFile(atPath: path) {
                return URL(fileURLWithPath: path, isDirectory: true)
            }
        }

        return nil
    }

    private func resolveDefaultProfile(in supportDirectory: URL) -> ZenProfile? {
        let profilesINIURL = supportDirectory.appendingPathComponent("profiles.ini")
        guard let contents = try? String(contentsOf: profilesINIURL, encoding: .utf8) else {
            return nil
        }

        let profiles = parseProfilesINI(contents)
        guard let selected = profiles.first(where: { $0.isDefault }) ?? profiles.first else {
            return nil
        }

        let directoryURL = supportDirectory.appendingPathComponent(selected.relativePath, isDirectory: true)
        guard fileManager.isReadableFile(atPath: directoryURL.path) else { return nil }

        return ZenProfile(
            name: selected.name,
            directoryURL: directoryURL,
            isDefault: selected.isDefault
        )
    }

    private func parseProfilesINI(_ contents: String) -> [ProfileEntry] {
        var entries: [ProfileEntry] = []
        var currentName = "Default"
        var currentPath = ""
        var currentIsDefault = false

        func commitCurrentEntry() {
            guard !currentPath.isEmpty else { return }
            entries.append(
                ProfileEntry(
                    name: currentName,
                    relativePath: currentPath,
                    isDefault: currentIsDefault
                )
            )
        }

        for line in contents.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("[Profile") {
                commitCurrentEntry()
                currentName = "Default"
                currentPath = ""
                currentIsDefault = false
                continue
            }

            if trimmed.hasPrefix("Name=") {
                currentName = String(trimmed.dropFirst("Name=".count))
            } else if trimmed.hasPrefix("Path=") {
                currentPath = String(trimmed.dropFirst("Path=".count))
            } else if trimmed.hasPrefix("Default=1") {
                currentIsDefault = true
            }
        }

        commitCurrentEntry()
        return entries
    }
}

private struct ProfileEntry {
    let name: String
    let relativePath: String
    let isDefault: Bool
}