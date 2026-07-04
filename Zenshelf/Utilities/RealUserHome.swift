import Darwin
import Foundation

/// Resolves the real user home directory, which differs from `NSHomeDirectory()` inside the app sandbox.
nonisolated enum RealUserHome {
    /// The actual user home path (e.g. `/Users/name`), not the sandbox container.
    static var path: String {
        if let directory = getpwuid(getuid())?.pointee.pw_dir {
            return String(cString: directory)
        }
        return NSHomeDirectory()
    }

    /// Application Support directory in the real user home.
    static var applicationSupportURL: URL {
        URL(fileURLWithPath: path, isDirectory: true)
            .appendingPathComponent("Library/Application Support", isDirectory: true)
    }
}