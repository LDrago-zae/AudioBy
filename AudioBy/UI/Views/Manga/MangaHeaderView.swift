import SwiftUI

public struct MangaHeaderView: View {
    @Bindable var nav = AppNavigationState.shared
    @Binding var isSearching: Bool
    public var onProfileTap: (() -> Void)? = nil

    public init(isSearching: Binding<Bool>, onProfileTap: (() -> Void)? = nil) {
        self._isSearching = isSearching
        self.onProfileTap = onProfileTap
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Hamburger button to open the Sidebar menu
            Button {
                nav.openSidebar()
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(MangaTheme.ink)
                    .frame(width: 40, height: 40)
                    .background(MangaTheme.surfaceLow)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(MangaTheme.hairline, lineWidth: 1))
            }
            .accessibilityLabel("Open Menu")

            // Brand title & Japanese subtitle
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text("Komorebi")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(MangaTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: true, vertical: false)
                    Circle()
                        .fill(MangaTheme.vermilion)
                        .frame(width: 5, height: 5)
                    Text("MANGA")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.0)
                        .foregroundStyle(MangaTheme.vermilion)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(MangaTheme.vermilionFixed, in: Capsule())
                        .fixedSize()
                }
                Text("Tokyo Bureau Edition")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(MangaTheme.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .layoutPriority(1)

            Spacer(minLength: 6)

            // Search toggle
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isSearching.toggle()
                    if isSearching || nav.mangaTab != .browse {
                        nav.mangaTab = .browse
                    }
                }
            } label: {
                Image(systemName: isSearching ? "xmark" : "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MangaTheme.ink)
                    .frame(width: 36, height: 36)
                    .background(MangaTheme.surfaceLow)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(MangaTheme.hairline, lineWidth: 1))
            }

            // Notifications
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(MangaTheme.ink)
                    .frame(width: 36, height: 36)
                    .background(MangaTheme.surfaceLow)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(MangaTheme.hairline, lineWidth: 1))

                Circle()
                    .fill(MangaTheme.vermilion)
                    .frame(width: 8, height: 8)
                    .padding(3)
            }

            // User Profile Avatar
            Button {
                onProfileTap?()
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [MangaTheme.vermilion, MangaTheme.vermilionDeep],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    Text("K")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(MangaTheme.surface.opacity(0.92))
        .overlay(
            Divider().background(MangaTheme.hairline),
            alignment: .bottom
        )
    }
}

