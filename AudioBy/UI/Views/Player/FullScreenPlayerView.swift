import SwiftUI
import AVKit

public struct FullScreenPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var playerService = AudioPlayerService.shared
    @Bindable var ttsService = TTSEngineService.shared

    @State private var showingSpeedSheet = false
    @State private var showingSleepTimerSheet = false
    @State private var showingChapterSheet = false
    @State private var showingBookmarkSheet = false
    @State private var showingCarMode = false
    @State private var showingVoicePicker = false
    @State private var showingReader = false
    @State private var isTranscriptionMode = true
    @Bindable var scenes = ReaderSceneStore.shared

    public init() {}

    public var body: some View {
        ZStack {
            if isTranscriptionMode {
                SceneBackdrop(scene: scenes.active, scrim: 0.62)
            } else {
                Theme.appBackground.ignoresSafeArea()
            }

            VStack(spacing: 16) {
                // Top Nav Bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.textDark)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Close player")

                    Spacer()

                    Menu {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isTranscriptionMode.toggle()
                            }
                        } label: {
                            Label(isTranscriptionMode ? "Show cover" : "Show text", systemImage: "text.quote")
                        }
                        Button { showingVoicePicker = true } label: {
                            Label("Voice", systemImage: "waveform")
                        }
                        Button { showingCarMode = true } label: {
                            Label("Car mode", systemImage: "car.fill")
                        }
                        Button { showingBookmarkSheet = true } label: {
                            Label("Bookmark", systemImage: "bookmark")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.textDark)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("More")
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)

                if let error = playerService.playbackError {
                    Text(error)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                if playerService.isBuffering {
                    ProgressView()
                        .tint(Theme.brandGreen)
                }

                Spacer(minLength: 6)

                // Middle Content: Artwork OR Live Karaoke Transcription
                if isTranscriptionMode {
                    KaraokeTranscriptionView(
                        chapter: playerService.currentChapter,
                        currentTime: playerService.currentTime,
                        playbackDuration: playerService.duration,
                        isLoading: {
                            if let id = playerService.currentBook?.id {
                                return AudiobookRepository.shared.loadingChapterBookIds.contains(id)
                            }
                            return false
                        }(),
                        onSeek: { time in
                            playerService.seek(to: time)
                        },
                        onRetry: {
                            guard let id = playerService.currentBook?.id else { return }
                            Task {
                                _ = await AudiobookRepository.shared.retryChapters(for: id)
                            }
                        }
                    )
                    .frame(maxWidth: 360, maxHeight: 310)
                    .padding(.horizontal, 20)
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                } else if let book = playerService.currentBook {
                    VStack(spacing: 18) {
                        CoverArtView(
                            title: book.title,
                            author: book.author,
                            gradientHexes: book.coverGradientColors,
                            coverImageURL: book.coverImageURL,
                            cornerRadius: 12,
                            shadowRadius: 16
                        )
                        .frame(width: 280, height: 280)
                        .shadow(color: Color.black.opacity(0.35), radius: 24, x: 0, y: 16)

                        VStack(spacing: 6) {
                            Text(book.title)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(Theme.textDark)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            Text(book.author)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.textMuted)
                                .lineLimit(1)
                            Text(playerService.currentChapter?.title ?? "Chapter 1")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.textMuted)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 28)
                    }
                    .transition(.opacity)
                }

                Spacer(minLength: 6)

                // Scrubber Slider
                PlaybackSlider(
                    currentTime: playerService.currentTime,
                    duration: playerService.duration,
                    onSeek: { time in
                        playerService.seek(to: time)
                    }
                )
                .padding(.horizontal, 24)

                // Playback Controls
                HStack(spacing: 36) {
                    Button {
                        playerService.jump(by: -15)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        Image(systemName: "gobackward.15")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(Theme.textDark)
                            .frame(width: 56, height: 56)
                    }
                    .accessibilityLabel("Back 15 seconds")

                    Button {
                        playerService.togglePlayPause()
                    } label: {
                        Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(Theme.appBackground)
                            .frame(width: 76, height: 76)
                            .background(Theme.textDark)
                            .clipShape(Circle())
                            .offset(x: playerService.isPlaying ? 0 : 2)
                    }
                    .accessibilityLabel(playerService.isPlaying ? "Pause" : "Play")

                    Button {
                        playerService.jump(by: 15)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        Image(systemName: "goforward.15")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(Theme.textDark)
                            .frame(width: 56, height: 56)
                    }
                    .accessibilityLabel("Forward 15 seconds")
                }
                .padding(.vertical, 4)

                VStack(spacing: 10) {
                    Button {
                        showingVoicePicker = true
                    } label: {
                        Text(playerService.useStudioVoice
                             ? "Read by \(ElevenLabsService.shared.selectedVoiceName)"
                             : "Read by \(ttsService.selectedVoiceName)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.textDark)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Theme.surfaceSubtle)
                            .clipShape(Capsule())
                    }

                    HStack(spacing: 8) {
                        playerPill(title: playerService.playbackSpeed.shortTitle, systemImage: "gauge.with.dots.needle.bottom.50percent") {
                            showingSpeedSheet = true
                        }
                        playerPill(
                            title: playerService.sleepTimerService.isActive ? playerService.sleepTimerService.formattedRemainingTime : "Sleep",
                            systemImage: playerService.sleepTimerService.isActive ? "moon.stars.fill" : "moon",
                            tint: playerService.sleepTimerService.isActive ? Theme.brandGreen : Theme.textDark
                        ) {
                            showingSleepTimerSheet = true
                        }
                        if playerService.currentBook != nil, playerService.currentChapter != nil {
                            playerPill(title: "Read", systemImage: "book.pages", tint: Theme.brandCyan) {
                                showingReader = true
                            }
                        }
                        playerPill(title: "Chapters", systemImage: "list.bullet") {
                            showingChapterSheet = true
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .fullScreenCover(isPresented: $showingCarMode) {
            CarModeView()
        }
        .sheet(isPresented: $showingSpeedSheet) {
            SpeedPickerSheet(currentSpeed: playerService.playbackSpeed) { speed in
                playerService.setSpeed(speed)
            }
        }
        .sheet(isPresented: $showingSleepTimerSheet) {
            SleepTimerSheet(activeOption: playerService.sleepTimerService.selectedOption) { option in
                playerService.setSleepTimer(option)
            }
        }
        .sheet(isPresented: $showingVoicePicker) {
            VoicePickerSheet()
        }
        .onChange(of: isTranscriptionMode) { _, enabled in
            guard enabled else { return }
            guard playerService.currentChapter?.hasReadableText != true else { return }
            guard let id = playerService.currentBook?.id else { return }
            Task {
                _ = await AudiobookRepository.shared.loadLiveChapters(for: id)
            }
        }
        .sheet(isPresented: $showingChapterSheet) {
            if let book = playerService.currentBook {
                ChapterListSheet(
                    chapters: book.chapters,
                    currentChapterIndex: playerService.currentChapterIndex
                ) { index in
                    playerService.loadAudiobook(book, chapterIndex: index, autoPlay: true)
                }
            }
        }
        .sheet(isPresented: $showingReader) {
            if let book = playerService.currentBook, let currentCh = playerService.currentChapter {
                BookReaderView(book: book, chapter: currentCh)
            }
        }
        .sheet(isPresented: $showingBookmarkSheet) {
            AddBookmarkSheet(
                timestamp: playerService.currentTime,
                chapterTitle: playerService.currentChapter?.title ?? "Session"
            ) { note in
                playerService.addBookmark(note: note)
            }
        }
    }

    private func playerPill(title: String, systemImage: String, tint: Color = Theme.textDark, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .foregroundColor(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Theme.surfaceWhite)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Theme.cardBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
