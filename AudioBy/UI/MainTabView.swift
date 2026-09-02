import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab: DockTab = .home
    @Bindable var playerService = AudioPlayerService.shared

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content Area
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

            // Bottom Stack: Mini-Player + Custom Floating Capsule Dock
            VStack(spacing: 8) {
                if playerService.currentBook != nil && playerService.isMiniPlayerVisible {
                    MiniPlayerView()
                }

                FloatingDockTabBar(selectedTab: $selectedTab)
                    .padding(.bottom, 10)
            }
            .padding(.horizontal, 16)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
