import AppKit
import SwiftUI

/// Displays a site favicon with a graceful fallback.
struct FaviconView: View {
    let data: Data?
    let title: String

    var body: some View {
        Group {
            if let image = image(from: data) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
            } else {
                Image(systemName: "globe")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: DesignTokens.iconSize, height: DesignTokens.iconSize)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.iconCornerRadius, style: .continuous))
        .accessibilityHidden(true)
    }

    private func image(from data: Data?) -> NSImage? {
        guard let data, let image = NSImage(data: data) else { return nil }
        image.size = NSSize(width: DesignTokens.iconSize, height: DesignTokens.iconSize)
        return image
    }
}