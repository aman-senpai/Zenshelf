import SwiftUI

/// A single Essential row in the menu bar dropdown.
struct EssentialMenuRow: View {
    let essential: Essential
    let faviconData: Data?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                FaviconView(data: faviconData, title: essential.displayTitle)
                Text(essential.displayTitle)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(height: DesignTokens.menuRowHeight)
        .accessibilityLabel(essential.displayTitle)
        .accessibilityHint("Opens this Essential in Zen Browser")
    }
}