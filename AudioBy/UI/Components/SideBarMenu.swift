import SwiftUI

public struct SideBarMenu: View {
    @Bindable var nav = AppNavigationState.shared
    @Bindable var auth = AuthService.shared
    @Bindable var mangaLibrary = MangaLibrary.shared
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true

    public init() {}

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Backdrop scrim
                if nav.isSidebarOpen {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            nav.closeSidebar()
                        }
                }

                // Drawer content
                if nav.isSidebarOpen {
                    drawerContent
                        .frame(width: DuoLayout.sidebarWidth(for: geo.size.width))
                        .frame(maxHeight: .infinity)
                    .background(MangaTheme.surfaceLow)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 24,
                            topTrailingRadius: 24
                        )
                    )
                    .overlay(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 24,
                            topTrailingRadius: 24
                        )
                        .stroke(MangaTheme.hairline, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.18), radius: 24, x: 8, y: 0)
                    .transition(.move(edge: .leading))
                    .gesture(
                        DragGesture(minimumDistance: 20)
                            .onEnded { value in
                                if value.translation.width < -40 {
                                    nav.closeSidebar()
                                }
                            }
                    )
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: nav.isSidebarOpen)
        }
    }

    private var drawerContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // User Header
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [MangaTheme.vermilion, MangaTheme.vermilionDeep],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                        let initial = auth.displayName.prefix(1).uppercased()
                        Text(initial.isEmpty ? "K" : initial)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(auth.displayName.isEmpty ? "Kenji" : auth.displayName)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(MangaTheme.ink)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Member • Free Tier")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(MangaTheme.secondary)
                            .lineLimit(1)
                    }
                    .layoutPriority(1)
                    Button {
                        nav.closeSidebar()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(MangaTheme.secondary)
                            .frame(width: 32, height: 32)
                            .background(MangaTheme.surfaceContainer)
                            .clipShape(Circle())
                    }
                }

                // Reading Streak badge
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(MangaTheme.vermilion)
                    Text("\(mangaLibrary.streakDays) Days Streak • \(mangaLibrary.streakMinutesToday)m today")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(MangaTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MangaTheme.surfaceContainer)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(MangaTheme.hairline, lineWidth: 1))
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 20)

            Divider().background(MangaTheme.hairline)

            // Primary Navigation Sections
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("MEDIA SECTIONS")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.0)
                        .foregroundStyle(MangaTheme.tertiary)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 4)

                    // Audiobooks Section
                    sectionRow(
                        section: .audiobooks,
                        badge: nil
                    )

                    // Manga Section (Separate & Highlighted!)
                    sectionRow(
                        section: .manga,
                        badge: "NEW MAKEOVER"
                    )

                    // Novels Section
                    sectionRow(
                        section: .novels,
                        badge: "NOW LIVE"
                    )

                    // Activity Section
                    sectionRow(
                        section: .activity,
                        badge: nil
                    )

                    // Settings Section
                    sectionRow(
                        section: .settings,
                        badge: nil
                    )

                    Text("QUICK SHORTCUTS")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.0)
                        .foregroundStyle(MangaTheme.tertiary)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 4)

                    Button {
                        nav.switchTo(.manga)
                        nav.mangaTab = .library
                    } label: {
                        shortcutRow(icon: "books.vertical", title: "Manga Library", count: "\(mangaLibrary.opened.count + mangaLibrary.imported.count)")
                    }

                    Button {
                        nav.switchTo(.audiobooks)
                    } label: {
                        shortcutRow(icon: "arrow.down.circle", title: "Audio Downloads", count: "\(DownloadManager.shared.downloadedBookIds.count)")
                    }

                    Button {
                        nav.isPresentingImporter = true
                        nav.closeSidebar()
                    } label: {
                        shortcutRow(icon: "square.and.arrow.down", title: "Import CBZ / PDF", count: "+")
                    }
                }
                .padding(.vertical, 8)
            }

            Divider().background(MangaTheme.hairline)

            // Footer
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: isDarkMode ? "moon.stars.fill" : "sun.max.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(MangaTheme.secondary)
                        Text(isDarkMode ? "Dark Theme" : "Light Paper")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(MangaTheme.ink)
                    }
                    Spacer()
                    Toggle("", isOn: $isDarkMode.animation(.easeInOut(duration: 0.25)))
                        .labelsHidden()
                        .tint(MangaTheme.vermilion)
                }

                HStack {
                    Text("Komorebi Engine 3.2")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(MangaTheme.tertiary)
                    Spacer()
                    Text("Tokyo / Studio Edition")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(MangaTheme.tertiary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 24)
        }
    }

    private func sectionRow(section: AppSection, badge: String?) -> some View {
        let isSelected = nav.currentSection == section

        return Button {
            nav.switchTo(section)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: section.icon)
                    .font(.system(size: 18, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? MangaTheme.vermilion : MangaTheme.secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(section.rawValue)
                        .font(.system(size: 15, weight: isSelected ? .bold : .semibold))
                        .foregroundStyle(isSelected ? MangaTheme.ink : MangaTheme.ink.opacity(0.85))
                    Text(section.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(MangaTheme.secondary)
                }

                Spacer()

                if let badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(MangaTheme.vermilion, in: Capsule())
                } else if isSelected {
                    Circle()
                        .fill(MangaTheme.vermilion)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isSelected ? MangaTheme.surfaceContainer : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? MangaTheme.hairline : Color.clear, lineWidth: 1)
            )
            .padding(.horizontal, 12)
        }
        .buttonStyle(.plain)
    }

    private func shortcutRow(icon: String, title: String, count: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(MangaTheme.secondary)
                .frame(width: 24)
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(MangaTheme.ink)
            Spacer()
            Text(count)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(MangaTheme.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(MangaTheme.surfaceContainer, in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}
