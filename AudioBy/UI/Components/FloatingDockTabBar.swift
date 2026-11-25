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
        case .home: return "house"
        case .explore: return "magnifyingglass"
        case .library: return "book"
        case .activity: return "heart"
        case .profile: return "person"
        }
    }

    public var selectedIconName: String {
        switch self {
        case .home: return "house.fill"
        case .explore: return "magnifyingglass"
        case .library: return "book.fill"
        case .activity: return "heart.fill"
        case .profile: return "person.fill"
        }
    }
}

public struct FloatingDockTabBar: View {
    @Binding public var selectedTab: DockTab

    private let iconSize: CGFloat = 46
    private let gap: CGFloat = 10

    public init(selectedTab: Binding<DockTab>) {
        self._selectedTab = selectedTab
    }

    public var body: some View {
        icons
            .padding(6)
            .background(MangaTheme.surfaceLow.opacity(0.95), in: Capsule())
            .overlay(Capsule().stroke(MangaTheme.hairline, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedTab)
            .fixedSize()
    }

    private var icons: some View {
        HStack(spacing: gap) {
            ForEach(DockTab.allCases, id: \.self) { tab in
                let selected = selectedTab == tab
                Button {
                    selectedTab = tab
                } label: {
                    ZStack {
                        Circle()
                            .fill(selected ? MangaTheme.vermilion : MangaTheme.surfaceContainer)
                        Image(systemName: selected ? tab.selectedIconName : tab.iconName)
                            .font(.system(size: 16, weight: selected ? .bold : .medium))
                            .foregroundStyle(selected ? Color.white : MangaTheme.ink)
                    }
                    .frame(width: iconSize, height: iconSize)
                    .contentShape(Circle())
                    .shadow(color: selected ? MangaTheme.vermilion.opacity(0.35) : Color.clear, radius: 6, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }
}
