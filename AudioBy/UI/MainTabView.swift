import SwiftUI

public struct MainTabView: View {
    @Bindable var playerService = AudioPlayerService.shared
    @Bindable var nav = AppNavigationState.shared
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true

    public init() {}

    public var body: some View {
        ZStack {
            MangaTheme.surface.ignoresSafeArea()

            // Main Content Area based on selected Section
            Group {
                switch nav.currentSection {
                case .audiobooks:
                    audiobooksSection
                case .manga:
                    MangaRootView()
                case .novels:
                    NovelsRootView()
                case .activity:
                    NavigationStack {
                        ActivityStatsView()
                    }
                case .settings:
                    NavigationStack {
                        ProfileDetailsView()
                    }
                }
            }

            // Global Slide-Out Sidebar Menu Drawer
            SideBarMenu()
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }

    private var audiobooksSection: some View {
        Group {
            switch nav.dockTab {
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
                FloatingDockTabBar(selectedTab: $nav.dockTab)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
            .background(Color.clear)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
