import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab: DockTab = .home
    @Bindable var playerService = AudioPlayerService.shared

    public init() {}

    public var body: some View {
        Group {
            switch selectedTab {
            case .home:
                HomeDashboardView()
            case .explore:
                NavigationStack {
                    ExploreSearchView()
                }
            case .library:
                LibraryView()
            case .activity:
                ActivityStatsView()
            case .profile:
                ProfileDetailsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 10) {
            VStack(spacing: 8) {
                if playerService.currentBook != nil && playerService.isMiniPlayerVisible {
                    MiniPlayerView()
                }
                FloatingDockTabBar(selectedTab: $selectedTab)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
            .background(Color.clear)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
