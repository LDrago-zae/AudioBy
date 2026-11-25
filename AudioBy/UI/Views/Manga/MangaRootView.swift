import SwiftUI

public struct MangaRootView: View {
    @Bindable var nav = AppNavigationState.shared
    @State private var isSearchActive = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                MangaTheme.surface.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top Manga Header with Hamburger button
                    MangaHeaderView(isSearching: $isSearchActive) {
                        nav.openSidebar()
                    }

                    // Main Tab Content
                    Group {
                        switch nav.mangaTab {
                        case .discover:
                            MangaHubView()
                        case .browse:
                            MangaBrowseView()
                        case .library:
                            MangaLibraryScreenView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // Dedicated Manga Bottom Dock Bar
                mangaBottomDock
            }
        }
    }

    private var mangaBottomDock: some View {
        HStack(spacing: 12) {
            ForEach(MangaSubTab.allCases) { tab in
                let isSel = nav.mangaTab == tab
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        nav.mangaTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 14, weight: isSel ? .bold : .medium))
                        if isSel {
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: .bold))
                                .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .foregroundStyle(isSel ? .white : MangaTheme.ink)
                    .padding(.horizontal, isSel ? 16 : 12)
                    .padding(.vertical, 10)
                    .background(
                        isSel ? MangaTheme.vermilion : Color.clear,
                        in: Capsule()
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            MangaTheme.surfaceLow.opacity(0.95)
        )
        .clipShape(Capsule())
        .overlay(Capsule().stroke(MangaTheme.hairline, lineWidth: 1))
        .shadow(color: MangaTheme.cardShadow, radius: 12, y: 4)
        .padding(.horizontal, 24)
        .padding(.bottom, 10)
    }
}

