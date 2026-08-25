import SwiftUI

public enum DockTab: Int, CaseIterable {
    case home = 0
    case path = 1
    case test = 2
    case profile = 3

    public var title: String {
        switch self {
        case .home: return "Home"
        case .path: return "Path"
        case .test: return "Test"
        case .profile: return "Profile"
        }
    }

    public var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .path: return "point.topleft.down.to.point.bottomright.curvepath"
        case .test: return "doc.text.fill"
        case .profile: return "person.crop.circle"
        }
    }
}

public struct FloatingDockTabBar: View {
    @Binding public var selectedTab: DockTab

    public init(selectedTab: Binding<DockTab>) {
        self._selectedTab = selectedTab
    }

    public var body: some View {
        HStack(spacing: 6) {
            ForEach(DockTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTab = tab
                    }
                } label: {
                    if selectedTab == tab {
                        // Active Pill: Vibrant Green with Icon + Label
                        HStack(spacing: 6) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 14, weight: .bold))
                            Text(tab.title)
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.brandGreenLight, Theme.brandGreen],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Theme.brandGreen.opacity(0.4), radius: 6, x: 0, y: 3)
                        )
                    } else {
                        // Inactive Icon
                        Image(systemName: tab.iconName)
                            .font(.system(size: 17))
                            .foregroundColor(Color.white.opacity(0.6))
                            .frame(width: 40, height: 40)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(red: 0.08, green: 0.09, blue: 0.11))
                .shadow(color: Color.black.opacity(0.35), radius: 14, x: 0, y: 6)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
}
