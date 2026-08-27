import SwiftUI

public struct AudiobookDetailView: View {
    public let book: Audiobook
    @Bindable var repository = AudiobookRepository.shared
    @Bindable var playerService = AudioPlayerService.shared
    @Bindable var downloadManager = DownloadManager.shared
    @Bindable var ttsService = TTSEngineService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var isSynopsisExpanded = false
    @State private var showingReader = false
    @State private var selectedChapterForReader: Chapter?
    @State private var showingVoicePicker = false

    public init(book: Audiobook) {
        self.book = book
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

    private func retryChapters() {
        Task {
            _ = await repository.retryChapters(for: activeBook.id)
        }
    }

    private var activeBook: Audiobook {
        repository.audiobooks.first(where: { $0.id == book.id }) ?? book
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

    public var body: some View {
        ZStack {
            Theme.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Top Custom Navigation Bar
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Theme.textDark)
                                .frame(width: 44, height: 44)
                                .background(Theme.surfaceWhite)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Theme.cardBorder, lineWidth: 1))
                        }

                        Spacer()

                        HStack(spacing: 12) {
                            // Favorite Heart Button
                            Button {
                                repository.toggleFavorite(for: activeBook.id)
                            } label: {
                                Image(systemName: activeBook.isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 18))
                                    .foregroundColor(activeBook.isFavorite ? .red : Theme.textDark)
                                    .frame(width: 44, height: 44)
                                    .background(Theme.surfaceWhite)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Theme.cardBorder, lineWidth: 1))
                            }

                            // Voice Selector Button
                            Button {
                                showingVoicePicker = true
                            } label: {
                                Image(systemName: "waveform.and.person.filled")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Theme.brandGreen)
                                    .frame(width: 44, height: 44)
                                    .background(Theme.surfaceWhite)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Theme.cardBorder, lineWidth: 1))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Hero Mockup Cover Art Card (Matching user screenshot)
                    ZStack {
                        // Ambient emerald glow
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Theme.brandGreen.opacity(0.25),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 180
                                )
                            )
                            .frame(width: 250, height: 250)

                        // Phone Frame Mockup with Cover Artwork
                        ZStack {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color(red: 0.08, green: 0.10, blue: 0.12))
                                .frame(width: 200, height: 230)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                                )
                                .shadow(color: Color.black.opacity(0.6), radius: 20, x: 0, y: 10)

                            VStack(spacing: 8) {
                                // Cover thumbnail
                                CoverArtView(
                                    title: activeBook.title,
                                    author: activeBook.author,
                                    gradientHexes: activeBook.coverGradientColors,
                                    coverImageURL: activeBook.coverImageURL,
                                    cornerRadius: 16,
                                    shadowRadius: 8
                                )
                                .frame(width: 145, height: 145)

                                // Mini audio bar inside frame
                                HStack(spacing: 8) {
                                    Circle().fill(Color.white.opacity(0.2)).frame(width: 12, height: 12)
                                    Capsule().fill(Color.white.opacity(0.15)).frame(width: 60, height: 3)
                                    Circle().fill(Color.white.opacity(0.2)).frame(width: 12, height: 12)
                                }
                            }
                            .padding(14)
                        }
                    }
                    .padding(.top, 4)

                    // Title & Author (Matching reference: Title in Bold White, Author in Cyan)
                    VStack(spacing: 6) {
                        Text(activeBook.title)
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(Theme.textDark)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)

                        Text(activeBook.author)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Theme.brandCyan)

                        Text("Narrated by \(activeBook.narrator)")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textMuted)
                    }

                    // Metadata Badges Row: [ ★ 4.8 (2.1k) ]  [ ▶ 30S SAMPLE ]  [ 📥 ]
                    HStack(spacing: 12) {
                        if activeBook.listenCount > 0 {
                            HStack(spacing: 5) {
                                Image(systemName: "headphones")
                                    .foregroundColor(Theme.brandGreen)
                                    .font(.system(size: 12))
                                Text("\(activeBook.formattedListenCount) plays")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Theme.textDark)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Theme.surfaceWhite)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Theme.cardBorder, lineWidth: 1))
                        } else if !activeBook.catalogSource.isEmpty {
                            Text(activeBook.catalogSource)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Theme.textDark)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Theme.surfaceWhite)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Theme.cardBorder, lineWidth: 1))
                        }

                        // 30S Sample Pill
                        Button {
                            if isPreviewingThisBook {
                                playerService.dismissSamplePreview()
                            } else {
                                playerService.playSamplePreview(for: activeBook)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: isPreviewingThisBook ? "stop.fill" : "play.circle.fill")
                                    .foregroundColor(Theme.brandGreen)
                                    .font(.system(size: 14))
                                Text(isPreviewingThisBook ? "STOP" : "30S SAMPLE")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundColor(Theme.textDark)
                                    .tracking(0.5)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Theme.surfaceWhite)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Theme.cardBorder, lineWidth: 1))
                        }

                        // Download Button
                        Button {
                            if downloadManager.isBookDownloaded(activeBook.id) {
                                downloadManager.deleteDownload(for: activeBook.id)
                            } else {
                                downloadManager.downloadAudiobook(activeBook)
                            }
                        } label: {
                            Group {
                                switch downloadStatus {
                                case .downloading(let progress):
                                    ProgressView(value: progress)
                                        .progressViewStyle(.circular)
                                        .tint(Theme.brandGreen)
                                        .frame(width: 16, height: 16)
                                case .downloaded:
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Theme.brandGreen)
                                        .font(.system(size: 16))
                                case .failed:
                                    Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 16))
                                default:
                                    Image(systemName: "arrow.down.to.line")
                                        .foregroundColor(Theme.textDark)
                                        .font(.system(size: 14, weight: .bold))
                                }
                            }
                            .frame(width: 42, height: 42)
                            .background(Theme.surfaceWhite)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Theme.cardBorder, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 20)

                    // Narration Audio Mode Picker (Native TTS Voice vs Human Stream)
                    HStack(spacing: 8) {
                        ForEach(PlaybackNarrationMode.allCases) { mode in
                            let isSel = playerService.narrationMode == mode
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    playerService.narrationMode = mode
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: mode == .nativeTTS ? "waveform.and.person.filled" : "antenna.radiowaves.left.and.right")
                                        .font(.system(size: 11))
                                    Text(mode.rawValue)
                                        .font(.system(size: 12, weight: isSel ? .bold : .medium))
                                }
                                .foregroundColor(isSel ? .black : Theme.textDark)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(isSel ? AnyShapeStyle(Theme.brandGreen) : AnyShapeStyle(Theme.surfaceWhite))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(isSel ? Color.clear : Theme.cardBorder, lineWidth: 1))
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Primary CTA Button: ▶ START LISTENING
                    VStack(spacing: 10) {
                        Button {
                            if isCurrentlyPlayingThisBook {
                                playerService.togglePlayPause()
                            } else {
                                playerService.playAudiobook(activeBook, chapterIndex: activeBook.currentChapterIndex, autoPlay: true)
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: isCurrentlyPlayingThisBook ? "pause.fill" : "play.fill")
                                    .font(.system(size: 16, weight: .heavy))
                                Text(isCurrentlyPlayingThisBook ? "PAUSE LISTENING" : (activeBook.progress > 0 ? "RESUME LISTENING" : "START LISTENING"))
                                    .font(.system(size: 15, weight: .heavy))
                                    .tracking(0.8)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Theme.brandGreen)
                            .cornerRadius(18)
                            .shadow(color: Theme.brandGreen.opacity(0.4), radius: 10, x: 0, y: 4)
                        }

                        // Read Chapter Text Button (TTS + Reader)
                        if let firstChapter = displayedChapters.first {
                            Button {
                                selectedChapterForReader = firstChapter
                                showingReader = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "book.fill")
                                        .font(.system(size: 13))
                                    Text("READ CHAPTER TEXT & NATIVE TTS")
                                        .font(.system(size: 12, weight: .bold))
                                        .tracking(0.5)
                                }
                                .foregroundColor(Theme.brandCyan)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Theme.surfaceWhite)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Theme.brandCyan.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        if let error = playerService.playbackError, playerService.currentBook?.id == activeBook.id {
                            Text(error)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.orange)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Synopsis")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Theme.textDark)

                        Text(activeBook.summary)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textMuted)
                            .lineSpacing(5)
                            .lineLimit(isSynopsisExpanded ? nil : 4)

                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isSynopsisExpanded.toggle()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(isSynopsisExpanded ? "READ LESS" : "READ FULL")
                                    .font(.system(size: 11, weight: .heavy))
                                Image(systemName: isSynopsisExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 10, weight: .heavy))
                            }
                            .foregroundColor(Theme.brandGreen)
                            .padding(.top, 4)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surfaceWhite)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Theme.cardBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Chapters")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Theme.textDark)
                            Spacer()
                            if isLoadingChapters {
                                HStack(spacing: 6) {
                                    ProgressView()
                                        .tint(Theme.brandGreen)
                                        .scaleEffect(0.8)
                                    Text("Fetching chapters...")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.brandGreen)
                                }
                            } else {
                                Button(action: retryChapters) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 11, weight: .bold))
                                        Text(displayedChapters.isEmpty ? "Retry" : "\(displayedChapters.count) chapters · Refresh")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(Theme.brandGreen)
                                }
                            }
                        }

                        if let chapterError, displayedChapters.isEmpty, !isLoadingChapters {
                            VStack(spacing: 10) {
                                Text(chapterError)
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.textMuted)
                                    .multilineTextAlignment(.center)
                                Button(action: retryChapters) {
                                    Text("Retry loading chapters")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(Theme.brandGreen)
                                        .clipShape(Capsule())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(18)
                            .background(Theme.surfaceWhite)
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.cardBorder, lineWidth: 1))
                        } else if displayedChapters.isEmpty && isLoadingChapters {
                            ProgressView()
                                .tint(Theme.brandGreen)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                        } else if displayedChapters.isEmpty {
                            VStack(spacing: 10) {
                                Text("No chapters loaded yet.")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Theme.textDark)
                                Button(action: retryChapters) {
                                    Text("Load chapters")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(Theme.brandGreen)
                                        .clipShape(Capsule())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }

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
                                                    .fill(isThisChapter ? Theme.brandGreen : Theme.surfaceSubtle)
                                                    .frame(width: 36, height: 36)

                                                if isThisChapter && playerService.isPlaying {
                                                    Image(systemName: "speaker.wave.2.fill")
                                                        .font(.system(size: 13))
                                                        .foregroundColor(.black)
                                                } else {
                                                    Text(String(format: "%02d", chapter.chapterNumber))
                                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                                        .foregroundColor(isThisChapter ? .black : Theme.textDark)
                                                }
                                            }

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(chapter.title)
                                                    .font(.system(size: 14, weight: isThisChapter ? .bold : .medium))
                                                    .foregroundColor(isThisChapter ? Theme.brandGreen : Theme.textDark)
                                                    .lineLimit(1)

                                                HStack(spacing: 6) {
                                                    Text(chapter.formattedDuration)
                                                    if chapter.remoteAudioURL != nil {
                                                        Text("· Audio")
                                                    } else if !chapter.fullText.isEmpty {
                                                        Text("· Voice")
                                                    }
                                                }
                                                .font(.system(size: 12))
                                                .foregroundColor(Theme.textMuted)
                                            }

                                            Spacer()
                                        }
                                    }

                                    Button {
                                        selectedChapterForReader = chapter
                                        showingReader = true
                                    } label: {
                                        Image(systemName: "book.pages")
                                            .font(.system(size: 15))
                                            .foregroundColor(Theme.brandCyan)
                                            .frame(width: 36, height: 36)
                                            .background(Theme.brandCyan.opacity(0.12))
                                            .clipShape(Circle())
                                    }
                                }
                                .padding(14)
                                .background(isThisChapter ? Theme.brandGreen.opacity(0.10) : Theme.surfaceWhite)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(isThisChapter ? Theme.brandGreen.opacity(0.35) : Theme.cardBorder, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // User Feedback & Reviews Section
                    if !activeBook.reviews.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("Listener Feedback & Reviews")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Theme.textDark)
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(Theme.brandGold)
                                        .font(.system(size: 12))
                                    Text(String(format: "%.1f", activeBook.rating))
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Theme.textDark)
                                }
                            }

                            VStack(spacing: 10) {
                                ForEach(activeBook.reviews) { review in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Image(systemName: "person.crop.circle.fill")
                                                .font(.system(size: 26))
                                                .foregroundColor(Theme.brandGreen)

                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(review.userName)
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(Theme.textDark)
                                                Text(review.dateString)
                                                    .font(.system(size: 11))
                                                    .foregroundColor(Theme.textMuted)
                                            }

                                            Spacer()

                                            HStack(spacing: 2) {
                                                ForEach(0..<5) { star in
                                                    Image(systemName: "star.fill")
                                                        .font(.system(size: 9))
                                                        .foregroundColor(Double(star) < review.rating ? Theme.brandGold : Theme.cardBorder)
                                                }
                                            }
                                        }

                                        Text(review.comment)
                                            .font(.system(size: 13))
                                            .foregroundColor(Theme.textMuted)
                                            .lineSpacing(3)

                                        HStack {
                                            Spacer()
                                            HStack(spacing: 4) {
                                                Image(systemName: "hand.thumbsup")
                                                    .font(.system(size: 11))
                                                Text("\(review.helpfulCount) found helpful")
                                                    .font(.system(size: 11))
                                            }
                                            .foregroundColor(Theme.textLightMuted)
                                        }
                                    }
                                    .padding(14)
                                    .background(Theme.surfaceWhite)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Theme.cardBorder, lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Bottom padding to clear the mini-player and dock completely
                    Spacer(minLength: 160)
                }
            }
        }
        .navigationBarHidden(true)
            .task {
                if displayedChapters.contains(where: { !$0.hasReadableText }) || displayedChapters.isEmpty {
                    _ = await repository.loadLiveChapters(for: activeBook.id)
                }
            }
        .sheet(item: $selectedChapterForReader) { chap in
            BookReaderView(book: activeBook, chapter: chap)
        }
        .sheet(isPresented: $showingVoicePicker) {
            VoicePickerSheet()
        }
    }
}
