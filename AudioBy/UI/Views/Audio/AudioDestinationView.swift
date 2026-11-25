import SwiftUI

public struct AudioDestinationView: View {
    @Bindable var nav = AppNavigationState.shared
    @Bindable var playerService = AudioPlayerService.shared
    @Bindable var repository = AudiobookRepository.shared

    @State private var selectedFilter: String = "All Audio"
    @State private var searchQuery: String = ""
    @State private var showingFullPlayer: Bool = false
    @State private var isPlayingPreview: Bool = false

    private let filterPills = ["All Audio", "Manga Audiobooks", "Novels", "Light Novels", "Full Cast"]

    public init() {}

    private var activeBook: Audiobook? {
        playerService.currentBook ?? repository.audiobooks.first
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                MangaTheme.surface.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        // Top Header with Hamburger Button
                        topHeader

                        // Prompt & Search Bar
                        searchSection

                        // Format Pills
                        filterPillsRow

                        // Continue Listening Bento Card
                        continueListeningBento

                        // Featured Premiere Hero Banner
                        featuredPremiereHero

                        // SECTION 1: Trending Manga Audiobooks
                        trendingMangaAudioSection

                        // SECTION 2: Popular Full-Length Novels
                        popularNovelsSection

                        // SECTION 3: Japanese Light Novel Audiobooks
                        lightNovelsSection

                        // SECTION 4: Top Cast & Narrators
                        topNarratorsSection

                        Spacer(minLength: 90)
                    }
                    .padding(.bottom, 20)
                }

                // Sticky Elevated Mini-Player Bar
                if let book = activeBook {
                    stickyMiniPlayer(for: book)
                }
            }
            .fullScreenCover(isPresented: $showingFullPlayer) {
                if let book = activeBook {
                    FullScreenAudiobookPlayerMakeover(book: book)
                }
            }
        }
    }

    // MARK: - Top Header
    private var topHeader: some View {
        HStack(spacing: 12) {
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

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text("Komorebi")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(MangaTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: true, vertical: false)
                    Text("AUDIO")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.0)
                        .foregroundStyle(MangaTheme.vermilion)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(MangaTheme.vermilionFixed, in: Capsule())
                        .fixedSize()
                }
                Text("Binaural Soundstage")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(MangaTheme.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .layoutPriority(1)

            Spacer(minLength: 6)

            Button {
                showingFullPlayer = true
            } label: {
                Image(systemName: "waveform")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(MangaTheme.vermilion)
                    .frame(width: 38, height: 38)
                    .background(MangaTheme.surfaceLow)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(MangaTheme.hairline, lineWidth: 1))
            }

            Button {
                nav.openSidebar()
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
                        .frame(width: 34, height: 34)
                    Text("K")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    // MARK: - Search Section
    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("IMMERSIVE AUDIO HUB")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(MangaTheme.vermilion)
                Text("What would you like to listen to?")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15))
                    .foregroundStyle(MangaTheme.secondary)
                TextField("Search voices, manga dramas, light novels...", text: $searchQuery)
                    .font(.system(size: 14))
                    .foregroundStyle(MangaTheme.ink)
                Button {
                    // Filter options
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MangaTheme.ink)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(MangaTheme.surfaceLow)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(MangaTheme.hairline, lineWidth: 1))
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Filter Pills
    private var filterPillsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filterPills, id: \.self) { pill in
                    let isSel = selectedFilter == pill
                    Button {
                        selectedFilter = pill
                    } label: {
                        HStack(spacing: 5) {
                            if isSel {
                                Circle().fill(Color.white).frame(width: 5, height: 5)
                            }
                            Text(pill)
                                .font(.system(size: 13, weight: isSel ? .bold : .medium))
                                .foregroundStyle(isSel ? .white : MangaTheme.ink)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(isSel ? MangaTheme.vermilion : MangaTheme.surfaceLow)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(isSel ? Color.clear : MangaTheme.hairline, lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Continue Listening Bento Card
    private var continueListeningBento: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(MangaTheme.vermilion)
                    Text("Continue Listening")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(MangaTheme.ink)
                }
                Spacer()
                Text("HISTORY")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(MangaTheme.secondary)
            }
            .padding(.horizontal, 16)

            Button {
                if let book = activeBook {
                    playerService.playAudiobook(book, chapterIndex: 0)
                    showingFullPlayer = true
                }
            } label: {
                HStack(spacing: 14) {
                    // 1:1 Disc Aspect Thumbnail
                    ZStack(alignment: .bottomTrailing) {
                        ZStack {
                            Circle()
                                .fill(MangaTheme.readerCard)
                                .frame(width: 72, height: 72)
                            Circle()
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                .frame(width: 56, height: 56)
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                .frame(width: 40, height: 40)
                            Image(systemName: "opticaldisc.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(MangaTheme.vermilion)
                        }

                        Text("34%")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(MangaTheme.readerCard, in: Capsule())
                    }

                    // Metadata
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("CHAPTER 7")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(MangaTheme.vermilion)
                            Text("• 38m left")
                                .font(.system(size: 11))
                                .foregroundStyle(MangaTheme.secondary)
                        }

                        Text(activeBook?.title ?? "Norwegian Wood")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(MangaTheme.ink)
                            .lineLimit(1)

                        Text("Ensemble Cast • \(activeBook?.author ?? "Haruki Murakami")")
                            .font(.system(size: 12))
                            .foregroundStyle(MangaTheme.secondary)
                            .lineLimit(1)

                        // Scrubber track
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(MangaTheme.surfaceContainer)
                                    .frame(height: 4)
                                Capsule()
                                    .fill(MangaTheme.vermilion)
                                    .frame(width: geo.size.width * 0.34, height: 4)
                            }
                        }
                        .frame(height: 4)
                        .padding(.top, 4)

                        HStack {
                            Text("03:14:20")
                                .font(.system(size: 10))
                                .foregroundStyle(MangaTheme.secondary)
                            Spacer()
                            Text("11h 45m total")
                                .font(.system(size: 10))
                                .foregroundStyle(MangaTheme.secondary)
                        }
                    }

                    // Play Button
                    Button {
                        if let book = activeBook {
                            playerService.playAudiobook(book, chapterIndex: 0)
                        }
                    } label: {
                        Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(MangaTheme.vermilion, in: Circle())
                            .shadow(color: MangaTheme.vermilion.opacity(0.3), radius: 6, y: 3)
                    }
                }
                .padding(14)
                .background(MangaTheme.surfaceLow)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(MangaTheme.hairline, lineWidth: 1))
                .padding(.horizontal, 16)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Featured Premiere Hero Banner
    private var featuredPremiereHero: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(hex: "#1E1B18"), Color(hex: "#2E2822")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 240)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    MangaBadge("FEATURED PREMIERE", isAccent: true)
                    MangaBadge("Binaural 3D Audio")
                    Spacer()
                    Text("52m • Ep 1")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.8))
                }

                Text("Demon Slayer: Sound Hashira Chronicles")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text("Narrated audio manga adaptation with original foley soundscapes, cinematic orchestral scoring, and dual voice cast.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.8))
                    .lineLimit(2)

                Text("Takahiro Sakurai, Natsuki Hanae • Cast of 14")
                    .font(.system(size: 11))
                    .foregroundStyle(MangaTheme.vermilionFixed)

                HStack(spacing: 12) {
                    Button {
                        if let book = activeBook {
                            playerService.playAudiobook(book, chapterIndex: 0)
                            showingFullPlayer = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "headphones")
                                .font(.system(size: 13, weight: .bold))
                            Text("Listen Now")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(MangaTheme.vermilion, in: Capsule())
                    }

                    Button {
                        isPlayingPreview.toggle()
                    } label: {
                        Image(systemName: isPlayingPreview ? "speaker.wave.3.fill" : "speaker.wave.2")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.15), in: Circle())
                    }

                    Spacer()

                    Button {
                        // Bookmark
                    } label: {
                        Image(systemName: "bookmark")
                            .font(.system(size: 15))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.15), in: Circle())
                    }
                }
                .padding(.top, 4)
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 16)
    }

    // MARK: - SECTION 1: Trending Manga Audiobooks
    private var trendingMangaAudioSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Trending Manga Audiobooks")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(MangaTheme.ink)
                        Circle().fill(MangaTheme.vermilion).frame(width: 5, height: 5)
                    }
                    Text("Voice acted with immersive Foley and dynamic SFX")
                        .font(.system(size: 11))
                        .foregroundStyle(MangaTheme.secondary)
                }
                Spacer()
                Text("SEE ALL")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(MangaTheme.vermilion)
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    audioCoverCard(title: "Jujutsu Sorcery Arc", meta: "Junya Enoki • Ep 1-12", duration: "48m / ep", badge: "FX Drama")
                    audioCoverCard(title: "Ghost Runner 2099", meta: "Kenjiro Tsuda • Vol. 1-3", duration: "6h 20m", badge: "Full Cast")
                    audioCoverCard(title: "Ronin of the Mist", meta: "Mamoru Miyano • Ch. 1-4", duration: "3h 15m", badge: "Binaural")
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func audioCoverCard(title: String, meta: String, duration: String, badge: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [MangaTheme.readerCard, Color(hex: "#38332E")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 130, height: 185)

                    VStack(alignment: .leading) {
                        Spacer()
                        Text(duration)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.5), in: Capsule())
                            .padding(6)
                    }

                    // Circular Play Trigger
                    Button {
                        if let book = activeBook {
                            playerService.playAudiobook(book, chapterIndex: 0)
                            showingFullPlayer = true
                        }
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(MangaTheme.vermilion, in: Circle())
                            .padding(8)
                    }
                }

                MangaBadge(badge, isAccent: true)
                    .padding(6)
            }

            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(MangaTheme.ink)
                .lineLimit(1)
                .frame(width: 130, alignment: .leading)

            Text(meta)
                .font(.system(size: 11))
                .foregroundStyle(MangaTheme.secondary)
                .lineLimit(1)
                .frame(width: 130, alignment: .leading)
        }
    }

    // MARK: - SECTION 2: Popular Full-Length Novels
    private var popularNovelsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Popular Full-Length Novels")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(MangaTheme.ink)
                    Text("Literary fiction, intricate mysteries & sci-fi")
                        .font(.system(size: 11))
                        .foregroundStyle(MangaTheme.secondary)
                }
                Spacer()
                Text("EXPLORE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(MangaTheme.vermilion)
            }
            .padding(.horizontal, 16)

            VStack(spacing: 8) {
                novelRowCard(title: "The Memory Police", author: "Yoko Ogawa • Narrated by Faye Chin", category: "DYSTOPIAN", duration: "10h 14m", rating: "★ 4.8")
                novelRowCard(title: "The Devotion of Suspect X", author: "Keigo Higashino • Tokyo Crime Series", category: "MYSTERY / NOIR", duration: "8h 42m", rating: "★ 4.9")
            }
            .padding(.horizontal, 16)
        }
    }

    private func novelRowCard(title: String, author: String, category: String, duration: String, rating: String) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(MangaTheme.surfaceContainer)
                .frame(width: 50, height: 70)
                .overlay(
                    Image(systemName: "book.closed")
                        .font(.system(size: 20))
                        .foregroundStyle(MangaTheme.vermilion)
                )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(category)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(MangaTheme.vermilion)
                    Text("• \(duration)")
                        .font(.system(size: 10))
                        .foregroundStyle(MangaTheme.secondary)
                }

                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)
                    .lineLimit(1)

                Text(author)
                    .font(.system(size: 11))
                    .foregroundStyle(MangaTheme.secondary)
                    .lineLimit(1)

                Text(rating)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(MangaTheme.vermilion)
            }

            Spacer()

            Button {
                if let book = activeBook {
                    playerService.playAudiobook(book, chapterIndex: 0)
                }
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(MangaTheme.vermilion)
            }
        }
        .padding(10)
        .background(MangaTheme.surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(MangaTheme.hairline, lineWidth: 1))
    }

    // MARK: - SECTION 3: Japanese Light Novels
    private var lightNovelsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Japanese Light Novels")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)
                MangaBadge("Official Audio")
                Spacer()
                Text("SERIES")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(MangaTheme.vermilion)
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    audioCoverCard(title: "Overlord: Vol 14", meta: "Kugane Maruyama • 9h 38m", duration: "Vol. 14", badge: "Light Novel")
                    audioCoverCard(title: "Bakemonogatari", meta: "NISIOISIN • 7h 52m", duration: "Part 01", badge: "Light Novel")
                    audioCoverCard(title: "Re:Zero", meta: "Tappei Nagatsuki • 8h 12m", duration: "Vol. 22", badge: "Light Novel")
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - SECTION 4: Top Cast & Narrators
    private var topNarratorsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Top Cast & Narrators")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(MangaTheme.ink)
                    Text("Listen to iconic voice actors and award-winning narrators")
                        .font(.system(size: 11))
                        .foregroundStyle(MangaTheme.secondary)
                }
                Spacer()
                Text("ALL VOICES")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(MangaTheme.vermilion)
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    narratorProfile(name: "Kenjiro Tsuda", tag: "Deep / Noir", icon: "mic.fill")
                    narratorProfile(name: "Saori Hayami", tag: "Serene / Poetic", icon: "music.note")
                    narratorProfile(name: "David Shih", tag: "Audie Awardee", icon: "star.fill")
                    narratorProfile(name: "Natsuki Hanae", tag: "Shounen Hero", icon: "bolt.fill")
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func narratorProfile(name: String, tag: String, icon: String) -> some View {
        VStack(spacing: 6) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(MangaTheme.surfaceContainer)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .foregroundStyle(MangaTheme.vermilion)
                    )

                Image(systemName: "play.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.white)
                    .padding(5)
                    .background(MangaTheme.vermilion, in: Circle())
            }

            Text(name)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(MangaTheme.ink)

            Text(tag)
                .font(.system(size: 10))
                .foregroundStyle(MangaTheme.secondary)
        }
    }

    // MARK: - Sticky Mini-Player Bar
    private func stickyMiniPlayer(for book: Audiobook) -> some View {
        Button {
            showingFullPlayer = true
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(MangaTheme.readerCard)
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: "headphones")
                            .font(.system(size: 16))
                            .foregroundStyle(MangaTheme.vermilion)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(book.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(MangaTheme.ink)
                            .lineLimit(1)
                        Text("• 1.25x")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(MangaTheme.vermilion)
                    }

                    Text("\(book.author) • Faye Chin")
                        .font(.system(size: 11))
                        .foregroundStyle(MangaTheme.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    playerService.seek(to: max(0, playerService.currentTime - 15))
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(.system(size: 16))
                        .foregroundStyle(MangaTheme.ink)
                }

                Button {
                    if playerService.isPlaying {
                        playerService.pause()
                    } else {
                        playerService.play()
                    }
                } label: {
                    Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(MangaTheme.vermilion, in: Circle())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(MangaTheme.surfaceLow)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(MangaTheme.hairline, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.12), radius: 12, y: 4)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .buttonStyle(.plain)
    }
}
