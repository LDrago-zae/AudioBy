import SwiftUI
import UIKit

/// Japanese editorial Home Dashboard for Audiobooks & Literary Novels.
/// Directly implements the Komorebi design language from stitch_reference/home_dashboard.
public struct HomeDashboardView: View {
    @Bindable var repository = AudiobookRepository.shared
    @Bindable var auth = AuthService.shared
    @Bindable var nav = AppNavigationState.shared

    @Bindable var reminders = ReminderService.shared
    @State private var showingSearch = false
    @State private var openedBook: Audiobook?

    public init() {}

    private var shelf: [Audiobook] { repository.filteredAudiobooks }

    private var featuredBook: Audiobook? {
        repository.audiobooks.first(where: { $0.rating >= 4.8 }) ?? repository.audiobooks.first
    }

    private var continueBooks: [Audiobook] {
        if !repository.continueListeningBooks.isEmpty {
            return repository.continueListeningBooks
        }
        return Array(repository.audiobooks.prefix(4))
    }

    private var greetingName: String {
        if !auth.displayName.isEmpty {
            return auth.displayName.components(separatedBy: " ").first ?? auth.displayName
        }
        return "Reader"
    }

    private var stats: UserListeningStats { StorageService.shared.loadStats() }

    private var greetingText: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Still up"
        }
    }

    private var todayMinutes: Int {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return stats.dailyHistory[f.string(from: Date())] ?? 0
    }

    /// Daily goal ring + one-tap resume: the reason to open the app every day.
    private var todayGoalCard: some View {
        let goal = max(stats.dailyTargetMinutes, 1)
        let done = min(Double(todayMinutes) / Double(goal), 1)
        let resume = continueBooks.first
        return HStack(spacing: 16) {
            ZStack {
                Circle().stroke(MangaTheme.hairline, lineWidth: 7)
                Circle()
                    .trim(from: 0, to: max(done, 0.02))
                    .stroke(MangaTheme.vermilion, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.smooth(duration: 0.8), value: done)
                VStack(spacing: 0) {
                    Text("\(todayMinutes)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(MangaTheme.ink)
                    Text("/ \(goal)m")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(MangaTheme.secondary)
                }
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text(done >= 1 ? "Goal reached. Keep it going." : "\(max(goal - todayMinutes, 0)) min left today")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)
                Text(stats.streakDays > 0 ? "\(stats.streakDays)-day streak. Don't break it." : "Listen today to start a streak.")
                    .font(.system(size: 12))
                    .foregroundStyle(MangaTheme.secondary)
                if let resume {
                    Button {
                        AudioPlayerService.shared.playAudiobook(resume, chapterIndex: resume.currentChapterIndex)
                    } label: {
                        Label("Resume", systemImage: "play.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(MangaTheme.vermilion, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(MangaTheme.surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous).stroke(MangaTheme.hairline, lineWidth: 1))
        .padding(.horizontal, 20)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                MangaTheme.surface.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        // 1. Top Header with Hamburger & Brand
                        komorebiHeader

                        // 2. Late Night Session & Greeting
                        greetingSection

                        todayGoalCard

                        WeeklyActivityCard()

                        StreakRewardsCard()

                        // 3. Quick Search Pill
                        quickSearchPill

                        // 4. Continue Listening & Reading Shelf
                        continueListeningSection

                        // 5. Featured Story Hero Card
                        if let featured = featuredBook {
                            featuredStoryCard(book: featured)
                        }

                        // 6. Format Switcher / Lounge Navigation Banners
                        hubBannersSection

                        // 7. Category Filter Pills
                        categoryPillsSection

                        // 8. Trending Literary Masterpieces (#1, #2, #3 Rail)
                        trendingSection

                        // 9. Catalog Library Grid
                        catalogGridSection

                        Spacer(minLength: 120)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(item: $openedBook) { book in
                AudiobookDetailView(book: book)
            }
            .refreshable {
                await repository.fetchRemoteAudiobooks()
            }
        }
    }

    // MARK: - 1. Top Header
    private var komorebiHeader: some View {
        HStack(spacing: 12) {
            Button {
                nav.openSidebar()
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(MangaTheme.ink)
                    .frame(width: 44, height: 44)
                    .background(MangaTheme.surfaceLow)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(MangaTheme.hairline, lineWidth: 1))
            }
            .accessibilityLabel("Open Menu")

            HStack(spacing: 8) {
                // Komorebi Brand Kanji / Mark
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(MangaTheme.vermilion)
                        .frame(width: 32, height: 32)
                    Text("木")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Audiobooks & Novels")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(MangaTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .allowsTightening(true)
                    Text("KOMOREBI AUDIO")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.0)
                        .foregroundStyle(MangaTheme.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            NavigationLink(destination: ExploreSearchView()) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MangaTheme.ink)
                    .frame(width: 38, height: 38)
                    .background(MangaTheme.surfaceLow)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(MangaTheme.hairline, lineWidth: 1))
            }
            .accessibilityLabel("Search")

            // Notifications with vermilion dot
            ThemeToggleButton()

            Button { Task { await reminders.toggle() } } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: reminders.enabled ? "bell.fill" : "bell")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MangaTheme.ink)
                        .frame(width: 38, height: 38)
                        .background(MangaTheme.surfaceLow)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(MangaTheme.hairline, lineWidth: 1))

                    if !reminders.enabled {
                        Circle()
                            .fill(MangaTheme.vermilion)
                            .frame(width: 8, height: 8)
                            .padding(8)
                    }
                }
            }
            .contextMenu { ReminderTimeMenu() }
            .accessibilityLabel(reminders.enabled ? "Turn off daily reminder" : "Turn on daily reminder")
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - 2. Greeting Section
    private var greetingSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(MangaTheme.vermilion)
                        .frame(width: 6, height: 6)
                    Text(greetingText.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(MangaTheme.secondary)
                }

                Text("\(greetingText), \(greetingName)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)
            }

            Spacer()

            // 14-Day Streak Pill
            HStack(spacing: 5) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(MangaTheme.vermilion)
                Text("\(stats.streakDays) \(stats.streakDays == 1 ? "Day" : "Days")")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(MangaTheme.surfaceHigh)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(MangaTheme.hairline, lineWidth: 1))
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 3. Quick Search Pill
    private var quickSearchPill: some View {
        NavigationLink(destination: ExploreSearchView()) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundStyle(MangaTheme.secondary)

                Text("Titles, authors, literary narrators…")
                    .font(.system(size: 14))
                    .foregroundStyle(MangaTheme.secondary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 12))
                    Text("FILTER")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.6)
                }
                .foregroundStyle(MangaTheme.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(MangaTheme.surfaceContainer)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(MangaTheme.surfaceLow)
            .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous)
                    .stroke(MangaTheme.hairline, lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 4. Continue Listening & Reading Shelf
    private var continueListeningSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            KomorebiSectionHeader(
                title: "Continue Listening",
                japaneseSub: "再生中 / ACTIVE SESSION",
                actionText: "Shelf (\(continueBooks.count))"
            ) {
                nav.openListeningShelf()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(continueBooks) { book in
                        continueCard(book: book)
                            .contentShape(Rectangle())
                            .onTapGesture { openedBook = book }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func continueCard(book: Audiobook) -> some View {
        let pct = Int(book.progress * 100)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                // 2:3 Cover
                ZStack(alignment: .topTrailing) {
                    CoverArtView(
                        title: book.title,
                        author: book.author,
                        gradientHexes: book.coverGradientColors,
                        coverImageURL: book.coverImageURL,
                        cornerRadius: 8,
                        ratio: 2/3
                    )
                    .frame(width: 68, height: 102)

                    MangaBadge(book.gutenbergId != nil ? "NOVEL" : "AUDIO")
                        .padding(4)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "headphones")
                            .font(.system(size: 10))
                        Text("Ch. \(book.currentChapterIndex + 1)")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(MangaTheme.secondary)

                    Text(book.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(MangaTheme.ink)
                        .lineLimit(2)

                    Text(book.author)
                        .font(.system(size: 12))
                        .foregroundStyle(MangaTheme.secondary)
                        .lineLimit(1)

                    HStack {
                        Text("\(pct)%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(MangaTheme.vermilion)

                        Spacer()

                        Button {
                            AudioPlayerService.shared.playAudiobook(book, chapterIndex: book.currentChapterIndex)
                        } label: {
                            Image(systemName: "play.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(MangaTheme.vermilion)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Progress Bar
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(MangaTheme.surfaceHighest)
                    .frame(height: 4)
                Capsule()
                    .fill(MangaTheme.vermilion)
                    .frame(width: 220 * CGFloat(Double(pct) / 100.0), height: 4)
            }
        }
        .padding(12)
        .frame(width: 250)
        .background(MangaTheme.surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous)
                .stroke(MangaTheme.hairline, lineWidth: 1)
        )
        .shadow(color: MangaTheme.cardShadow, radius: 8, y: 2)
    }

    // MARK: - 5. Featured Story Hero Card
    private func featuredStoryCard(book: Audiobook) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                // Background Ambient Visual
                GeometryReader { geo in
                    CoverArtView(
                        title: book.title,
                        author: book.author,
                        gradientHexes: book.coverGradientColors,
                        coverImageURL: book.coverImageURL,
                        cornerRadius: 0,
                        ratio: 16/9
                    )
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                MangaTheme.ink.opacity(0.4),
                                MangaTheme.ink.opacity(0.85)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 200)

                // Top badges
                VStack {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(MangaTheme.vermilion)
                            Text(String(format: "%.2f Rating", book.rating > 0 ? book.rating : 4.95))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(MangaTheme.ink)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(MangaTheme.surface.opacity(0.92))
                        .clipShape(Capsule())

                        Spacer()

                        Text("FEATURED OF THE MONTH")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.8)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.65))
                            .clipShape(Capsule())
                    }
                    .padding(12)
                    Spacer()
                }

                // Title Overlay
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        MangaBadge(book.category.rawValue, isAccent: true)
                        MangaBadge("UNABRIDGED")
                    }

                    Text(book.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(book.author)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(14)
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: MangaTheme.cardRadius,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: MangaTheme.cardRadius
                )
            )

            // Bottom Editorial Content & Actions
            VStack(alignment: .leading, spacing: 12) {
                Text(book.summary.isEmpty ? "An immersive literary masterpiece brought to life with full-cast voice recordings and rich soundscapes." : book.summary)
                    .font(.system(size: 13))
                    .foregroundStyle(MangaTheme.secondary)
                    .lineLimit(2)

                HStack(spacing: 10) {
                    Button {
                        AudioPlayerService.shared.playAudiobook(book, chapterIndex: 0)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 16))
                            Text("Listen Now")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(MangaTheme.vermilion)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    NavigationLink(destination: AudiobookDetailView(book: book)) {
                        HStack(spacing: 6) {
                            Image(systemName: "bookmark")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Details")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(MangaTheme.ink)
                        .padding(.horizontal, 16)
                        .frame(height: 44)
                        .background(MangaTheme.surfaceHigh)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(14)
            .background(MangaTheme.surfaceLow)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: MangaTheme.cardRadius,
                    bottomTrailingRadius: MangaTheme.cardRadius,
                    topTrailingRadius: 0
                )
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous)
                .stroke(MangaTheme.hairline, lineWidth: 1)
        )
        .shadow(color: MangaTheme.cardShadow, radius: 10, y: 3)
        .padding(.horizontal, 20)
    }

    // MARK: - 6. Hub Banners Section
    private var hubBannersSection: some View {
        VStack(spacing: 10) {
            // Manga Lounge Ribbon
            Button {
                nav.switchTo(.manga)
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [MangaTheme.vermilion, MangaTheme.vermilionDeep],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 42, height: 42)
                        Image(systemName: "book.pages.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("MANGA LOUNGE")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.0)
                                .foregroundStyle(MangaTheme.vermilion)
                            MangaBadge("JAPANESE SCANS", isAccent: true)
                        }
                        Text("Explore Manga, Manhwa & Webtoons")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(MangaTheme.ink)
                    }

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(MangaTheme.vermilion)
                        .frame(width: 28, height: 28)
                        .background(MangaTheme.vermilionFixed.opacity(0.4))
                        .clipShape(Circle())
                }
                .padding(12)
                .background(MangaTheme.surfaceLow)
                .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: MangaTheme.cardRadius).stroke(MangaTheme.hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)

            // Dual Cards: Tokyo Audio Lounge & Light Novels
            HStack(spacing: 10) {
                NavigationLink(destination: AudioDestinationView()) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(MangaTheme.surfaceContainer)
                                .frame(width: 36, height: 36)
                            Image(systemName: "headphones")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(MangaTheme.vermilion)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Audio Lounge")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(MangaTheme.ink)
                            Text("Binaural & Dramas")
                                .font(.system(size: 11))
                                .foregroundStyle(MangaTheme.secondary)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(MangaTheme.surfaceLow)
                    .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: MangaTheme.cardRadius).stroke(MangaTheme.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button {
                    nav.switchTo(.novels)
                } label: {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(MangaTheme.surfaceContainer)
                                .frame(width: 36, height: 36)
                            Image(systemName: "text.book.closed.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(MangaTheme.vermilion)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Light Novels")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(MangaTheme.ink)
                            Text("Full Reader")
                                .font(.system(size: 11))
                                .foregroundStyle(MangaTheme.secondary)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(MangaTheme.surfaceLow)
                    .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: MangaTheme.cardRadius).stroke(MangaTheme.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 7. Category Filter Pills
    private var categoryPillsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AudiobookCategory.allCases, id: \.self) { cat in
                    let isSel = repository.selectedCategory == cat
                    Button {
                        repository.selectedCategory = cat
                        Task { await repository.fetchRemoteAudiobooks(for: cat) }
                    } label: {
                        HStack(spacing: 6) {
                            if isSel {
                                Circle()
                                    .fill(MangaTheme.vermilionFixed)
                                    .frame(width: 5, height: 5)
                            }
                            Text(cat == .all ? "All Catalog" : cat.rawValue)
                                .font(.system(size: 12, weight: isSel ? .bold : .medium))
                        }
                        .foregroundStyle(isSel ? .white : MangaTheme.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(isSel ? MangaTheme.vermilion : MangaTheme.surfaceLow)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(isSel ? Color.clear : MangaTheme.hairline, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - 8. Trending Section (#1, #2, #3 Rail)
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            KomorebiSectionHeader(
                title: "Trending Masterpieces",
                japaneseSub: "名作選 / EDITORIAL PICKS"
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    let topPicks = Array(shelf.sorted { $0.rating > $1.rating }.prefix(5))
                    ForEach(Array(topPicks.enumerated()), id: \.element.id) { index, book in
                        NavigationLink(destination: AudiobookDetailView(book: book)) {
                            trendingCard(book: book, rank: index + 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func trendingCard(book: Audiobook, rank: Int) -> some View {
        HStack(spacing: 12) {
            ZStack(alignment: .topLeading) {
                CoverArtView(
                    title: book.title,
                    author: book.author,
                    gradientHexes: book.coverGradientColors,
                    coverImageURL: book.coverImageURL,
                    cornerRadius: 8,
                    ratio: 2/3
                )
                .frame(width: 64, height: 96)

                Text("#\(rank)")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(MangaTheme.vermilion)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 8,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 6,
                            topTrailingRadius: 0
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(MangaTheme.vermilion)
                    Text(String(format: "%.1f", book.rating > 0 ? book.rating : 4.9))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(MangaTheme.ink)
                }

                Text(book.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)
                    .lineLimit(2)

                Text(book.author)
                    .font(.system(size: 11))
                    .foregroundStyle(MangaTheme.secondary)
                    .lineLimit(1)

                Spacer(minLength: 0)

                HStack(spacing: 4) {
                    Image(systemName: "headphones")
                        .font(.system(size: 10))
                    Text(book.formattedTotalDuration)
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(MangaTheme.tertiary)
            }
        }
        .padding(10)
        .frame(width: 230, height: 116)
        .background(MangaTheme.surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: MangaTheme.cardRadius).stroke(MangaTheme.hairline, lineWidth: 1))
        .shadow(color: MangaTheme.cardShadow, radius: 6, y: 2)
    }

    // MARK: - 9. Catalog Grid Section
    private var catalogGridSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            KomorebiSectionHeader(
                title: "Curated Catalog",
                japaneseSub: "文庫本 / UNABRIDGED EDITIONS",
                actionText: "Browse All (\(shelf.count))"
            )

            if repository.isLoadingRemote && shelf.isEmpty {
                HStack(spacing: 10) {
                    ProgressView().tint(MangaTheme.vermilion)
                    Text("Loading literary collection…")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(MangaTheme.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else if shelf.isEmpty {
                VStack(spacing: 8) {
                    Text("No audiobooks found in this category")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MangaTheme.secondary)
                    Button {
                        Task { await repository.fetchRemoteAudiobooks() }
                    } label: {
                        Text("Reset & Refresh")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(MangaTheme.vermilion)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 14),
                        GridItem(.flexible(), spacing: 14)
                    ],
                    spacing: 18
                ) {
                    ForEach(shelf) { book in
                        NavigationLink(destination: AudiobookDetailView(book: book)) {
                            KomorebiBookCard(book: book)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

/// Horizontal strip whose drag is owned by UIKit, so the page scroll cannot take it back mid-swipe.
private struct ShelfStrip<Content: View>: UIViewRepresentable {
    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scroll = UIScrollView()
        scroll.alwaysBounceHorizontal = true
        scroll.alwaysBounceVertical = false
        scroll.showsHorizontalScrollIndicator = false
        scroll.showsVerticalScrollIndicator = false
        scroll.isDirectionalLockEnabled = true
        scroll.delaysContentTouches = false
        scroll.canCancelContentTouches = true
        scroll.backgroundColor = .clear
        scroll.contentInsetAdjustmentBehavior = .never

        let host = UIHostingController(rootView: content)
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            host.view.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor)
        ])
        context.coordinator.host = host
        return scroll
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.host?.rootView = content
    }

    final class Coordinator {
        var host: UIHostingController<Content>?
    }
}
