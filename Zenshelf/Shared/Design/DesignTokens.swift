import SwiftUI

/// Visual rhythm and motion constants aligned with Apple Human Interface Guidelines.
enum DesignTokens {
    // MARK: - Layout

    static let menuWidth: CGFloat = 260
    static let menuRowHeight: CGFloat = 28
    static let iconSize: CGFloat = 16
    static let iconCornerRadius: CGFloat = 4
    static let sectionSpacing: CGFloat = 6
    static let horizontalPadding: CGFloat = 12
    static let verticalPadding: CGFloat = 8

    // MARK: - Motion

    static let animationDuration: Double = 0.2
    static let springResponse: Double = 0.28
    static let springDamping: Double = 0.86

    // MARK: - Animation Helpers

    static var standardAnimation: Animation {
        .spring(response: springResponse, dampingFraction: springDamping)
    }

    static func motionAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : standardAnimation
    }
}