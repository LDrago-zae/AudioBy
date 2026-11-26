import SwiftUI

public struct FullScreenAudiobookPlayerMakeover: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    public let book: Audiobook

    @Bindable private var playerService = AudioPlayerService.shared
    @State private var showingSpeedSheet = false
    @State private var showingTimerSheet = false
    @State private var showingChaptersSheet = false
    @State private var showingBookmarkToast = false

    public init(book: Audiobook) {
        self.book = book
    }

    private var currentChapter: Chapter? {
        playerService.currentChapter
    }

    public var body: some View {
        ZStack {
            // Ambient Glow Backdrop
            MangaTheme.readerCard.ignoresSafeArea()

            RadialGradient(
                colors: [MangaTheme.vermilion.opacity(0.18), Color.clear],
                center: .top,
                startRadius: 20,
                endRadius: 400
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                let isDualPane = DuoLayout.isWide(geo.size, sizeClass: horizontalSizeClass) || DuoLayout.isLandscape(geo.size)

                VStack(spacing: 16) {
                    // Top Action Bar
                    topActionBar

                    if isDualPane {
                        HStack(alignment: .center, spacing: 28) {
                            artworkAndTitleSection
                                .frame(maxWidth: geo.size.width * 0.44)

                            ScrollView(showsIndicators: false) {
                                VStack(spacing: 18) {
                                    waveformAndScrubberSection
                                    primaryPlaybackControls
                                    secondaryToolbar
                                    upNextRibbon
                                }
                                .padding(.vertical, 8)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        Spacer(minLength: 8)

                        // Artwork & Title Details
                        artworkAndTitleSection

                        // Dynamic Audio Waveform & Scrubber
                        waveformAndScrubberSection

                        // Primary Playback Controls
                        primaryPlaybackControls

                        // Secondary Contextual Toolbar
                        secondaryToolbar

                        // Up Next Cue Ribbon
                        upNextRibbon

                        Spacer(minLength: 16)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
            }

            // Bookmark Toast
            if showingBookmarkToast {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "bookmark.fill")
                            .foregroundStyle(MangaTheme.vermilion)
                        Text("Bookmark saved at \(formatTime(playerService.currentTime))")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.85), in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    .padding(.bottom, 90)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showingSpeedSheet) {
            SpeedPickerSheet(currentSpeed: playerService.playbackSpeed) { speed in
                playerService.setSpeed(speed)
            }
            .presentationDetents([.fraction(0.35)])
        }
        .sheet(isPresented: $showingTimerSheet) {
            SleepTimerSheet(activeOption: playerService.sleepTimerService.selectedOption) { option in
                playerService.setSleepTimer(option)
            }
            .presentationDetents([.fraction(0.45)])
        }
        .sheet(isPresented: $showingChaptersSheet) {
            if let book = playerService.currentBook {
                ChapterListSheet(
                    chapters: book.chapters,
                    currentChapterIndex: playerService.currentChapterIndex
                ) { index in
                    playerService.loadAudiobook(book, chapterIndex: index, autoPlay: true)
                }
                .presentationDetents([.fraction(0.65), .large])
            }
        }
    }

    // MARK: - Top Action Bar
    private var topActionBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.1), in: Circle())
            }

            Spacer()

            // Category Pill Badge
            HStack(spacing: 6) {
                Circle()
                    .fill(MangaTheme.vermilion)
                    .frame(width: 5, height: 5)
                Text(book.category.rawValue.uppercased() + " • VOL. 3")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.12), in: Capsule())

            Spacer()

            Button {
                // More options
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.1), in: Circle())
            }
        }
    }

    // MARK: - Center Showcase: Artwork & Title
    private var artworkAndTitleSection: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .topTrailing) {
                CoverArtView(
                    title: book.title,
                    author: book.author,
                    gradientHexes: book.coverGradientColors,
                    coverImageURL: book.coverImageURL
                )
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: 270)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.4), radius: 18, y: 10)

                // Dolby Atmos Badge
                HStack(spacing: 4) {
                    Image(systemName: "headphones")
                        .font(.system(size: 10))
                    Text("DOLBY ATMOS")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.8)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.75), in: Capsule())
                .padding(10)
            }

            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "book.pages")
                        .font(.system(size: 11))
                        .foregroundStyle(MangaTheme.vermilion)
                    Text(currentChapter?.title ?? "Chapter 4: The Barcarolle of Transience")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MangaTheme.vermilionFixed)
                        .lineLimit(1)
                }

                Text(book.title)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(book.author)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.8))

                Text("Narrated by \(book.narrator)")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Dynamic Audio Waveform & Scrubber Section
    private var waveformAndScrubberSection: some View {
        VStack(spacing: 10) {
            // Stylized Visual Waveform
            HStack(spacing: 4) {
                ForEach(0..<28, id: \.self) { bar in
                    let isPlayed = Double(bar) / 28.0 <= (playerService.duration > 0 ? playerService.currentTime / playerService.duration : 0.35)
                    let height: CGFloat = CGFloat(14 + (bar * 7) % 36)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(isPlayed ? MangaTheme.vermilion : Color.white.opacity(0.2))
                        .frame(width: 4, height: height)
                }
            }
            .frame(height: 52)
            .padding(.horizontal, 8)

            // Scrubber Slider
            PlaybackSlider(
                currentTime: playerService.currentTime,
                duration: playerService.duration,
                onSeek: { time in
                    playerService.seek(to: time)
                }
            )

            // Precision Timestamps
            HStack {
                Text(formatTime(playerService.currentTime))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))

                Spacer()

                Text("CH. TOTAL \(formatTime(playerService.duration))")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))

                Spacer()

                Text("-\(formatTime(max(0, playerService.duration - playerService.currentTime)))")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    // MARK: - Primary Playback Controls
    private var primaryPlaybackControls: some View {
        HStack(spacing: 24) {
            Button {
                playerService.previousChapter()
            } label: {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.85))
            }

            Button {
                playerService.jump(by: -15)
            } label: {
                Image(systemName: "gobackward.15")
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
            }

            // Big Vermilion Master Play/Pause Button
            Button {
                if playerService.isPlaying {
                    playerService.pause()
                } else {
                    playerService.play()
                }
            } label: {
                Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 68, height: 68)
                    .background(MangaTheme.vermilion, in: Circle())
                    .shadow(color: MangaTheme.vermilion.opacity(0.4), radius: 12, y: 4)
            }

            Button {
                playerService.jump(by: 30)
            } label: {
                Image(systemName: "goforward.30")
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
            }

            Button {
                playerService.nextChapter()
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    // MARK: - Secondary Contextual Toolbar
    private var secondaryToolbar: some View {
        HStack(spacing: 10) {
            // Speed Selector
            Button {
                showingSpeedSheet = true
            } label: {
                VStack(spacing: 2) {
                    Text("\(String(format: "%.2f", playerService.playbackSpeed.rawValue))x")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Speed")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }

            // Sleep Timer
            Button {
                showingTimerSheet = true
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(MangaTheme.vermilion)
                    Text("End Ch.")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }

            // Bookmark Clip Note
            Button {
                withAnimation {
                    showingBookmarkToast = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { showingBookmarkToast = false }
                }
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                    Text("Clip Note")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }

            // Chapters List
            Button {
                showingChaptersSheet = true
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                    Text("Chapters")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Up Next Cue Ribbon
    private var upNextRibbon: some View {
        Button {
            playerService.nextChapter()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "text.line.first.and.arrowtriangle.forward")
                    .font(.system(size: 14))
                    .foregroundStyle(MangaTheme.vermilion)

                VStack(alignment: .leading, spacing: 1) {
                    Text("UP NEXT • 48:12")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                    Text("Chapter 5: Concerto of Iron and Shadow")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(10)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(max(0, time))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
