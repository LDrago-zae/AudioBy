import SwiftUI

/// Japanese editorial details screen for Audiobooks & Literary Novels.
/// Direct Komorebi design language matching stitch_reference/manga_details.
public struct AudiobookDetailView: View {
    public let book: Audiobook
    @Bindable var repository = AudiobookRepository.shared
    @Bindable var playerService = AudioPlayerService.shared
    @Bindable var downloadManager = DownloadManager.shared
    @Bindable var ttsService = TTSEngineService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var isSynopsisExpanded = false
    @State private var isLoadingSynopsis = false
    @State private var showingReader = false
    @State private var selectedChapterForReader: Chapter?
    @State private var showingVoicePicker = false
    @State private var showingPaywall = false
    @State private var ext = ExternalRatings.none
    @State private var selectedTab: DetailTab = .chapters

    public enum DetailTab: String, CaseIterable, Identifiable {
        case chapters = "Chapters"
        case synopsis = "Synopsis"
        case reviews = "Reviews"

        public var id: String { rawValue }
    }

    public init(book: Audiobook) {
        self.book = book
    }

    private var activeBook: Audiobook {
        repository.audiobooks.first(where: { $0.id == book.id }) ?? book
    }

    private var isLoadingChapters: Bool {
        repository.loadingChapterBookIds.contains(activeBook.id)
    }

    private var chapterError: String? {
        repository.chapterErrors[activeBook.id]
    }

    private var displayedChapters: [Chapter] {
        activeBook.chapters
    }

    private var isCurrentlyPlayingThisBook: Bool {
        (playerService.currentBook?.id == activeBook.id && playerService.isPlaying) ||
        (ttsService.isPlaying && ttsService.currentBookTitle == activeBook.title)
    }

    private var isPreviewingThisBook: Bool {
        playerService.isPlayingSamplePreview && playerService.previewBook?.id == activeBook.id
    }

    private var downloadStatus: DownloadStatus {
        downloadManager.downloadStatuses[activeBook.id] ?? (downloadManager.isBookDownloaded(activeBook.id) ? .downloaded(localURL: URL(fileURLWithPath: "")) : .notDownloaded)
    }

    private func retryChapters() {
        Task {
            _ = await repository.retryChapters(for: activeBook.id)
        }
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            MangaTheme.surface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Top Navigation Bar
                    topNavBar

                    // 2:3 Cover Artwork Presentation
                    coverShowcase

                    // Title & Editorial Metadata
                    metadataSection

                    BookStatsStrip(
                        rating: ext.average > 0 ? ext.average : activeBook.rating,
                        reviews: max(ext.count, activeBook.reviewCount) + ReviewStore.shared.reviews(for: activeBook.id).count,
                        duration: activeBook.formattedTotalDuration
                    )

                    PlusUpsellRow(showingPaywall: $showingPaywall)

                    // 30s Audio Sample Preview Ribbon
                    samplePreviewRibbon

                    // Narration Audio Mode Picker
                    narrationModeSelector

                    // Segmented Tabs (Chapters, Synopsis, Reviews)
                    segmentedTabPicker

                    // Tab Content
                    Group {
                        switch selectedTab {
                        case .chapters:
                            chaptersTabContent
                        case .synopsis:
                            synopsisTabContent
                        case .reviews:
                            reviewsTabContent
                        }
                    }

                    Spacer(minLength: 160)
                }
            }

            // Sticky Bottom Action Dock
            bottomActionDock
        }
        .navigationBarHidden(true)
        .task { ext = await RatingsService.shared.ratings(for: activeBook) }
        .task {
            if activeBook.catalogSource == CatalogSourceKind.userPDF.rawValue { return }
            if displayedChapters.contains(where: { !$0.hasReadableText }) || displayedChapters.isEmpty {
                _ = await repository.loadLiveChapters(for: activeBook.id)
            }
        }
        .task(id: activeBook.id) {
            guard AudiobookAPIService.needsSynopsis(activeBook.summary) else { return }
            isLoadingSynopsis = true
            _ = await repository.enrichSynopsis(for: activeBook.id)
            isLoadingSynopsis = false
        }
        .sheet(item: $selectedChapterForReader) { chap in
            BookReaderView(book: activeBook, chapter: chap)
        }
        .sheet(isPresented: $showingVoicePicker) {
            VoicePickerSheet()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    // MARK: - Top Nav Bar
    private var topNavBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)
                    .frame(width: 44, height: 44)
                    .background(MangaTheme.surfaceLow)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(MangaTheme.hairline, lineWidth: 1))
            }

            Spacer()

            HStack(spacing: 6) {
                Text("文庫")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(MangaTheme.vermilion)
                Text("Audio Novel")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)
            }

            Spacer()

            HStack(spacing: 10) {
                // Voice selector
                Button {
                    showingVoicePicker = true
                } label: {
                    Image(systemName: "waveform.and.person.filled")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MangaTheme.vermilion)
                        .frame(width: 44, height: 44)
                        .background(MangaTheme.surfaceLow)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(MangaTheme.hairline, lineWidth: 1))
                }

                // Favorite button
                Button {
                    repository.toggleFavorite(for: activeBook.id)
                } label: {
                    Image(systemName: activeBook.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                        .foregroundStyle(activeBook.isFavorite ? MangaTheme.vermilion : MangaTheme.ink)
                        .frame(width: 44, height: 44)
                        .background(MangaTheme.surfaceLow)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(MangaTheme.hairline, lineWidth: 1))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Cover Showcase (2:3 Aspect Ratio)
    private var coverShowcase: some View {
        ZStack(alignment: .topTrailing) {
            CoverArtView(
                title: activeBook.title,
                author: activeBook.author,
                gradientHexes: activeBook.coverGradientColors,
                coverImageURL: activeBook.coverImageURL,
                cornerRadius: MangaTheme.cardRadius,
                shadowRadius: 18,
                ratio: 2/3
            )
            .frame(width: 190, height: 285)
            .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous)
                    .stroke(MangaTheme.hairline, lineWidth: 1)
            )
            .shadow(color: MangaTheme.cardShadow, radius: 18, y: 10)

            // Top Badge
            MangaBadge(activeBook.gutenbergId != nil ? "HQ AUDIO" : "UNABRIDGED", isAccent: true)
                .padding(10)
        }
        .padding(.top, 6)
    }

    // MARK: - Metadata Section
    private var metadataSection: some View {
        VStack(spacing: 10) {
            // Japanese Tag
            Text("文学名作 / UNABRIDGED CLASSIC")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(MangaTheme.vermilion)

            Text(activeBook.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(MangaTheme.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Text("By \(activeBook.author) • Narrated by \(activeBook.narrator.isEmpty ? "Cast" : activeBook.narrator)")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(MangaTheme.secondary)

            // Meta Chips Row
            HStack(spacing: 8) {
                // Status with pulsing dot
                HStack(spacing: 5) {
                    Circle()
                        .fill(MangaTheme.vermilion)
                        .frame(width: 6, height: 6)
                    Text("COMPLETE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(MangaTheme.ink)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(MangaTheme.surfaceLow)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(MangaTheme.hairline, lineWidth: 1))

                // Rating
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(MangaTheme.vermilion)
                    Text(String(format: "%.1f", activeBook.rating > 0 ? activeBook.rating : 4.9))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(MangaTheme.ink)
                    if activeBook.reviewCount > 0 {
                        Text("(\(activeBook.reviewCount))")
                            .font(.system(size: 10))
                            .foregroundStyle(MangaTheme.secondary)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(MangaTheme.surfaceLow)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(MangaTheme.hairline, lineWidth: 1))

                // Duration
                HStack(spacing: 4) {
                    Image(systemName: "headphones")
                        .font(.system(size: 10))
                        .foregroundStyle(MangaTheme.secondary)
                    Text(activeBook.formattedTotalDuration)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(MangaTheme.ink)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(MangaTheme.surfaceLow)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(MangaTheme.hairline, lineWidth: 1))
            }
        }
    }

    // MARK: - 30s Sample Preview Ribbon
    private var samplePreviewRibbon: some View {
        HStack(spacing: 12) {
            Button {
                if isPreviewingThisBook {
                    playerService.dismissSamplePreview()
                } else {
                    playerService.playSamplePreview(for: activeBook)
                }
            } label: {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(MangaTheme.vermilion)
                            .frame(width: 34, height: 34)
                        Image(systemName: isPreviewingThisBook ? "stop.fill" : "play.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isPreviewingThisBook ? "PREVIEW PLAYING" : "30-SEC SAMPLE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(MangaTheme.ink)
                        Text(isPreviewingThisBook ? "Tap to pause audio snippet" : "Hear voice actor intro")
                            .font(.system(size: 11))
                            .foregroundStyle(MangaTheme.secondary)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // Dynamic Waveform Visualizer
            HStack(spacing: 2.5) {
                ForEach(0..<10) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(isPreviewingThisBook ? MangaTheme.vermilion : MangaTheme.secondary.opacity(0.35))
                        .frame(width: 2.5, height: isPreviewingThisBook ? CGFloat([14, 22, 10, 26, 16, 28, 12, 20, 15, 8][i]) : 8)
                        .animation(.easeInOut(duration: 0.35).repeatForever().delay(Double(i) * 0.04), value: isPreviewingThisBook)
                }
            }

            // Download Button
            Button {
                if downloadManager.isBookDownloaded(activeBook.id) {
                    downloadManager.deleteDownload(for: activeBook.id)
                } else {
                    if EntitlementService.shared.canDownloadMore {
                        downloadManager.downloadAudiobook(activeBook)
                    } else {
                        showingPaywall = true
                    }
                }
            } label: {
                Group {
                    switch downloadStatus {
                    case .downloading(let progress):
                        ProgressView(value: progress)
                            .progressViewStyle(.circular)
                            .tint(MangaTheme.vermilion)
                            .frame(width: 16, height: 16)
                    case .downloaded:
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(MangaTheme.vermilion)
                    default:
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 18))
                            .foregroundStyle(MangaTheme.ink)
                    }
                }
                .frame(width: 36, height: 36)
                .background(MangaTheme.surfaceHigh)
                .clipShape(Circle())
            }
        }
        .padding(12)
        .background(MangaTheme.surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: MangaTheme.cardRadius).stroke(MangaTheme.hairline, lineWidth: 1))
        .padding(.horizontal, 20)
    }

    // MARK: - Narration Mode Selector
    private var narrationModeSelector: some View {
        HStack(spacing: 8) {
            ForEach(PlaybackNarrationMode.allCases) { mode in
                let isSel = playerService.narrationMode == mode
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        playerService.narrationMode = mode
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode == .nativeTTS ? "waveform.and.person.filled" : "antenna.radiowaves.left.and.right")
                            .font(.system(size: 11))
                        Text(mode.rawValue)
                            .font(.system(size: 11, weight: isSel ? .bold : .medium))
                    }
                    .foregroundStyle(isSel ? .white : MangaTheme.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(isSel ? MangaTheme.vermilion : MangaTheme.surfaceLow)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(isSel ? Color.clear : MangaTheme.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Segmented Tab Picker
    private var segmentedTabPicker: some View {
        HStack(spacing: 6) {
            ForEach(DetailTab.allCases) { tab in
                let isSel = selectedTab == tab
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 13, weight: isSel ? .bold : .medium))
                        .foregroundStyle(isSel ? MangaTheme.ink : MangaTheme.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isSel ? MangaTheme.surfaceLow : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSel ? MangaTheme.hairline : Color.clear, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(MangaTheme.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }

    // MARK: - Tab: Chapters
    private var chaptersTabContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(displayedChapters.count) Chapters Available")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)

                Spacer()

                if isLoadingChapters {
                    HStack(spacing: 6) {
                        ProgressView().tint(MangaTheme.vermilion).scaleEffect(0.8)
                        Text("Syncing chapters…")
                            .font(.system(size: 11))
                            .foregroundStyle(MangaTheme.secondary)
                    }
                } else {
                    Button(action: retryChapters) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 10, weight: .bold))
                            Text("Refresh")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(MangaTheme.vermilion)
                    }
                }
            }
            .padding(.horizontal, 20)

            if displayedChapters.isEmpty {
                VStack(spacing: 8) {
                    Text("No chapters loaded yet.")
                        .font(.system(size: 13))
                        .foregroundStyle(MangaTheme.secondary)
                    Button("Fetch Chapters", action: retryChapters)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(MangaTheme.vermilion)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(displayedChapters.enumerated()), id: \.element.id) { index, chapter in
                        let isThisChapter = playerService.currentBook?.id == activeBook.id && playerService.currentChapterIndex == index
                        HStack(spacing: 12) {
                            Button {
                                playerService.loadAudiobook(activeBook, chapterIndex: index, autoPlay: true)
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(isThisChapter ? MangaTheme.vermilion : MangaTheme.surfaceContainer)
                                            .frame(width: 34, height: 34)

                                        if isThisChapter && playerService.isPlaying {
                                            Image(systemName: "speaker.wave.2.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(.white)
                                        } else {
                                            Text(String(format: "%02d", chapter.chapterNumber))
                                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                .foregroundStyle(isThisChapter ? .white : MangaTheme.ink)
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(chapter.title)
                                            .font(.system(size: 13, weight: isThisChapter ? .bold : .medium))
                                            .foregroundStyle(isThisChapter ? MangaTheme.vermilion : MangaTheme.ink)
                                            .lineLimit(1)

                                        HStack(spacing: 6) {
                                            Text(chapter.formattedDuration)
                                            if chapter.remoteAudioURL != nil {
                                                Text("• Audio")
                                            } else if !chapter.fullText.isEmpty {
                                                Text("• Voice Text")
                                            }
                                        }
                                        .font(.system(size: 11))
                                        .foregroundStyle(MangaTheme.secondary)
                                    }

                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)

                            // Read text sheet button
                            Button {
                                selectedChapterForReader = chapter
                                showingReader = true
                            } label: {
                                Image(systemName: "book.pages")
                                    .font(.system(size: 14))
                                    .foregroundStyle(MangaTheme.vermilion)
                                    .frame(width: 32, height: 32)
                                    .background(MangaTheme.vermilionFixed.opacity(0.4))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(12)
                        .background(isThisChapter ? MangaTheme.vermilionFixed.opacity(0.2) : MangaTheme.surfaceLow)
                        .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous)
                                .stroke(isThisChapter ? MangaTheme.vermilion.opacity(0.4) : MangaTheme.hairline, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Tab: Synopsis
    private var synopsisTabContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Synopsis & Literary Background")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(MangaTheme.ink)

            if isLoadingSynopsis && AudiobookAPIService.needsSynopsis(activeBook.summary) {
                HStack(spacing: 10) {
                    ProgressView().tint(MangaTheme.vermilion)
                    Text("Fetching literary synopsis…")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(MangaTheme.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            } else {
                Text(
                    AudiobookAPIService.needsSynopsis(activeBook.summary)
                    ? "No published synopsis was found for this title yet."
                    : activeBook.summary
                )
                .font(.system(size: 14))
                .lineSpacing(5)
                .foregroundStyle(MangaTheme.secondary)
                .lineLimit(isSynopsisExpanded ? nil : 8)

                if !AudiobookAPIService.needsSynopsis(activeBook.summary) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isSynopsisExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(isSynopsisExpanded ? "SHOW LESS" : "READ FULL SYNOPSIS")
                                .font(.system(size: 11, weight: .bold))
                            Image(systemName: isSynopsisExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(MangaTheme.vermilion)
                    }
                }
            }

            Divider()
                .background(MangaTheme.hairline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Publication Details")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)

                HStack {
                    Text("Source Catalog")
                        .font(.system(size: 12))
                        .foregroundStyle(MangaTheme.secondary)
                    Spacer()
                    Text(activeBook.catalogSource.isEmpty ? "Standard Archive" : activeBook.catalogSource)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MangaTheme.ink)
                }

                HStack {
                    Text("Format")
                        .font(.system(size: 12))
                        .foregroundStyle(MangaTheme.secondary)
                    Spacer()
                    Text("Unabridged Audio Novel")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MangaTheme.ink)
                }
            }
        }
        .padding(16)
        .background(MangaTheme.surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: MangaTheme.cardRadius).stroke(MangaTheme.hairline, lineWidth: 1))
        .padding(.horizontal, 20)
    }

    // MARK: - Tab: Reviews
    private var reviewsTabContent: some View {
        ReviewsCarousel(bookId: activeBook.id, publishedReviews: ext.reviews.isEmpty ? activeBook.reviews : ext.reviews)
    }

    private var legacyReviewsTabContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Listener Feedback")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(MangaTheme.vermilion)
                    Text(String(format: "%.1f", activeBook.rating > 0 ? activeBook.rating : 4.9))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(MangaTheme.ink)
                }
            }

            if activeBook.reviews.isEmpty {
                Text("No listener reviews written yet. Be the first to share your thoughts!")
                    .font(.system(size: 13))
                    .foregroundStyle(MangaTheme.secondary)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 10) {
                    ForEach(activeBook.reviews) { rev in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(rev.userName)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(MangaTheme.ink)
                                Spacer()
                                Text(rev.dateString)
                                    .font(.system(size: 10))
                                    .foregroundStyle(MangaTheme.secondary)
                            }

                            Text(rev.comment)
                                .font(.system(size: 12))
                                .foregroundStyle(MangaTheme.secondary)
                                .lineSpacing(3)
                        }
                        .padding(12)
                        .background(MangaTheme.surfaceContainer)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .padding(16)
        .background(MangaTheme.surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: MangaTheme.cardRadius).stroke(MangaTheme.hairline, lineWidth: 1))
        .padding(.horizontal, 20)
    }

    // MARK: - Sticky Bottom Action Dock
    private var bottomActionDock: some View {
        HStack(spacing: 12) {
            // Main Play/Pause Button
            Button {
                if playerService.currentBook?.id == activeBook.id {
                    playerService.togglePlayPause()
                } else {
                    playerService.playAudiobook(activeBook, chapterIndex: activeBook.currentChapterIndex, autoPlay: true)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isCurrentlyPlayingThisBook ? "pause.fill" : "play.fill")
                        .font(.system(size: 16))
                    Text(isCurrentlyPlayingThisBook ? "Pause" : (activeBook.progress > 0 ? "Resume Ch. \(activeBook.currentChapterIndex + 1)" : "Listen Now"))
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(MangaTheme.vermilion)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: MangaTheme.vermilion.opacity(0.35), radius: 8, y: 3)
            }

            // Try free: 30-second sample, only before the listener has started the book
            if activeBook.progress == 0 {
                Button {
                    if isPreviewingThisBook { playerService.dismissSamplePreview() }
                    else { playerService.playSamplePreview(for: activeBook) }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isPreviewingThisBook ? "stop.fill" : "headphones")
                            .font(.system(size: 14, weight: .bold))
                        Text(isPreviewingThisBook ? "Stop" : "Try free")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(MangaTheme.vermilion)
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(MangaTheme.vermilion, lineWidth: 1.5))
                }
            }

            // Read Novel Text Button
            if let firstChapter = displayedChapters.first {
                Button {
                    selectedChapterForReader = firstChapter
                    showingReader = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "book.pages")
                            .font(.system(size: 15, weight: .bold))
                        Text("Read Text")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(MangaTheme.ink)
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(MangaTheme.surfaceHigh)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(MangaTheme.hairline, lineWidth: 1))
                }
            }
        }
        .padding(12)
        .background(MangaTheme.surfaceLow.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(MangaTheme.hairline, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
        .duoFloatingBarWidth()
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }
}
