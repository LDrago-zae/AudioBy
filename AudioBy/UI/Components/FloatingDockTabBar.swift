import SwiftUI

public enum DockTab: Int, CaseIterable {
    case home = 0
    case explore = 1
    case library = 2
    case activity = 3
    case profile = 4

    public var title: String {
        switch self {
        case .home: return "Discover"
        case .explore: return "Explore"
        case .library: return "Library"
        case .activity: return "Activity"
        case .profile: return "Settings"
        }
    }

    public var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .explore: return "magnifyingglass"
        case .library: return "books.vertical.fill"
        case .activity: return "flame.fill"
        case .profile: return "gearshape.fill"
        }
    }
}

public struct FloatingDockTabBar: View {
    @Binding public var selectedTab: DockTab

    public init(selectedTab: Binding<DockTab>) {
        self._selectedTab = selectedTab
    }

    public var body: some View {
        HStack(spacing: 4) {
            ForEach(DockTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTab = tab
                    }
                } label: {
                    if selectedTab == tab {
                        // Active Pill: Vibrant Green with Icon + Label
                        HStack(spacing: 5) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 13, weight: .bold))
                            Text(tab.title)
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(Theme.brandGreen))
                    } else {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 16))
                            .foregroundColor(Theme.textMuted)
                            .frame(width: 36, height: 36)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Theme.surfaceWhite)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                .overlay(Capsule().stroke(Theme.cardBorder, lineWidth: 1))
        )
    }
}
