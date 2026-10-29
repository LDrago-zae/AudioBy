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
    @Namespace private var glass

    private let iconSize: CGFloat = 46
    private let gap: CGFloat = 10

    public init(selectedTab: Binding<DockTab>) {
        self._selectedTab = selectedTab
    }

    public var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 12) {
                icons
                    .padding(6)
                    .glassEffect(.regular, in: Capsule())
            }
            .animation(.smooth(duration: 0.45), value: selectedTab)
            .fixedSize()
        } else {
            icons
                .padding(6)
                .background(.ultraThinMaterial, in: Capsule())
                .animation(.smooth(duration: 0.45), value: selectedTab)
                .fixedSize()
        }
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
                            .fill(Color.white.opacity(0.16))
                        if selected {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.64, blue: 0.28),
                                            Theme.ember
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .modifier(FocusGlass(namespace: glass))
                        }
                        Image(systemName: selected ? tab.selectedIconName : tab.iconName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.white)
                    }
                    .frame(width: iconSize, height: iconSize)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }
}

private struct FocusGlass: ViewModifier {
    let namespace: Namespace.ID

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.tint(Theme.ember).interactive(), in: Circle())
                .glassEffectID("focus", in: namespace)
        } else {
            content
        }
    }
}
