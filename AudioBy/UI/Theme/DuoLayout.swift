import SwiftUI

/// Responsive layout helpers for iPhone Duo (folded cover screen & unfolded dual-pane/wide canvas),
/// standard iPhones, and landscape orientations.
public enum DuoLayout {
    /// Adaptive card grid columns:
    /// - 2 columns on compact/folded iPhone widths (~320-430pt)
    /// - 3-4 columns automatically when unfolded on iPhone Duo or rotated to landscape
    public static let adaptiveCardColumns: [GridItem] = [
        GridItem(.adaptive(minimum: 138, maximum: 220), spacing: 14)
    ]

    /// Returns true when running on an unfolded wide canvas, regular size class, or wide landscape viewport.
    public static func isWide(_ size: CGSize, sizeClass: UserInterfaceSizeClass? = nil) -> Bool {
        sizeClass == .regular || size.width >= 580
    }

    /// Returns true when the viewport is wider than tall.
    public static func isLandscape(_ size: CGSize) -> Bool {
        size.width > size.height
    }

    /// Responsive sidebar width that never overflows narrow folded screens or balloons on unfolded screens.
    public static func sidebarWidth(for containerWidth: CGFloat) -> CGFloat {
        min(320, max(260, containerWidth * 0.82))
    }
}

public extension View {
    /// Constrains long-form reading, detail, and form content to a comfortable width centered on unfolded Duo screens.
    func duoReadableContainer(maxWidth: CGFloat = 720) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }

    /// Constrains floating docks, mini-players, and sticky bottom bars on wide unfolded screens.
    func duoFloatingBarWidth(maxWidth: CGFloat = 520) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}
