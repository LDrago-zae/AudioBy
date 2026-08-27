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
    @State private var isTranscriptionMode = false

    public init() {}

    public var body: some View {
        ZStack {
            Theme.appBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                // Top Nav Bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Theme.textDark)
                            .frame(width: 44, height: 44)
                            .background(Theme.surfaceWhite)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Theme.cardBorder, lineWidth: 1)
                            )
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text(isTranscriptionMode ? "LIVE TRANSCRIPT" : "NOW PLAYING")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.brandGreen)
                            .tracking(1.2)
                        Text(playerService.currentBook?.title ?? "Audiobook")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.textDark)
                            .lineLimit(1)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        // Toggle Live Transcription Mode
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isTranscriptionMode.toggle()
                            }
                        } label: {
                            Image(systemName: isTranscriptionMode ? "text.quote" : "quote.bubble")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(isTranscriptionMode ? .black : Theme.textDark)
                                .frame(width: 40, height: 40)
                                .background(isTranscriptionMode ? Theme.brandGreen : Theme.surfaceWhite)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Theme.cardBorder, lineWidth: 1)
                                )
                        }

                        // Voice Selector Button
                        Button {
                            showingVoicePicker = true
                        } label: {
                            Image(systemName: "waveform.and.person.filled")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Theme.brandGreen)
                                .frame(width: 40, height: 40)
                                .background(Theme.surfaceWhite)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Theme.cardBorder, lineWidth: 1)
                                )
                        }

                        // Car Mode Launch Button
                        Button {
                            showingCarMode = true
                        } label: {
                            Image(systemName: "car.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Theme.textDark)
                                .frame(width: 40, height: 40)
                                .background(Theme.surfaceWhite)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Theme.cardBorder, lineWidth: 1)
                                )
                        }

                        // Bookmark Button
                        Button {
                            showingBookmarkSheet = true
                        } label: {
                            Image(systemName: "bookmark")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Theme.textDark)
                                .frame(width: 40, height: 40)
                                .background(Theme.surfaceWhite)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Theme.cardBorder, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

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
                } else {
                    // Large Ambient Artwork Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Theme.surfaceWhite)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(Theme.cardBorder, lineWidth: 1)
                            )

                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top) {
                                if let book = playerService.currentBook {
                                    CoverArtView(
                                        title: book.title,
                                        author: book.author,
                                        gradientHexes: book.coverGradientColors,
                                        coverImageURL: book.coverImageURL,
                                        cornerRadius: 14,
                                        shadowRadius: 6
                                    )
                                    .frame(width: 80, height: 80)
                                }

                                Spacer()

                                // Voice Clarity Boost Chip
                                Button {
                                    playerService.isVocalClarityBoosted.toggle()
                                    let gen = UIImpactFeedbackGenerator(style: .light)
                                    gen.impactOccurred()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: playerService.isVocalClarityBoosted ? "waveform.badge.magnifyingglass" : "waveform")
                                            .font(.system(size: 11))
                                        Text(playerService.isVocalClarityBoosted ? "Voice Boost ON" : "Voice Boost")
                                            .font(.system(size: 11, weight: .bold))
                                    }
                                    .foregroundColor(playerService.isVocalClarityBoosted ? .black : Theme.textDark)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(playerService.isVocalClarityBoosted ? Theme.brandGreen : Theme.surfaceSubtle)
                                    .clipShape(Capsule())
                                }
                            }

                            Spacer()

                            Text(playerService.currentChapter?.title ?? "Chapter 1")
                                .font(.system(size: 21, weight: .heavy, design: .rounded))
                                .foregroundColor(Theme.textDark)
                                .lineLimit(2)

                            Text("Narrated by \(playerService.currentBook?.narrator ?? "Classic Narrator")")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Theme.textMuted)

                            // Waveform visualizer
                            WaveformVisualizer(isPlaying: playerService.isPlaying, barCount: 26, activeColor: Theme.brandGreen)
                                .padding(.top, 4)
                        }
                        .padding(18)
                    }
                    .frame(maxWidth: 340, maxHeight: 290)
                    .shadow(color: Color.black.opacity(0.4), radius: 18, x: 0, y: 8)
                    .padding(.horizontal, 20)
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
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
                HStack(spacing: 22) {
                    // 15s Jump Back
                    Button {
                        playerService.jump(by: -15)
                        let gen = UIImpactFeedbackGenerator(style: .medium)
                        gen.impactOccurred()
                    } label: {
                        Image(systemName: "gobackward.15")
                            .font(.system(size: 22))
                            .foregroundColor(Theme.textDark)
                            .frame(width: 46, height: 46)
                            .background(Theme.surfaceWhite)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Theme.cardBorder, lineWidth: 1))
                    }

                    // Previous Chapter
                    Button {
                        playerService.previousChapter()
                    } label: {
                        Image(systemName: "backward.end.fill")
                            .font(.system(size: 19))
                            .foregroundColor(Theme.textDark)
                    }

                    // Big Play / Pause Button
                    Button {
                        playerService.togglePlayPause()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Theme.activeGreenGradient)
                                .frame(width: 72, height: 72)
                                .shadow(color: Theme.brandGreen.opacity(0.45), radius: 16, x: 0, y: 6)

                            Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.black)
                                .offset(x: playerService.isPlaying ? 0 : 2)
                        }
                    }

                    // Next Chapter
                    Button {
                        playerService.nextChapter()
                    } label: {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 19))
                            .foregroundColor(Theme.textDark)
                    }

                    // 30s Jump Forward
                    Button {
                        playerService.jump(by: 30)
                        let gen = UIImpactFeedbackGenerator(style: .medium)
                        gen.impactOccurred()
                    } label: {
                        Image(systemName: "goforward.30")
                            .font(.system(size: 22))
                            .foregroundColor(Theme.textDark)
                            .frame(width: 46, height: 46)
                            .background(Theme.surfaceWhite)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Theme.cardBorder, lineWidth: 1))
                    }
                }
                .padding(.vertical, 6)

                // Bottom Tool Bar (Speed, Sleep, Chapters, Reader)
                HStack(spacing: 10) {
                    Button {
                        showingSpeedSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                                .font(.system(size: 12))
                            Text(playerService.playbackSpeed.shortTitle)
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(Theme.textDark)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Theme.surfaceWhite)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Theme.cardBorder, lineWidth: 1))
                    }

                    Button {
                        showingSleepTimerSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: playerService.sleepTimerService.isActive ? "moon.stars.fill" : "moon")
                                .font(.system(size: 12))
                                .foregroundColor(playerService.sleepTimerService.isActive ? Theme.brandGreen : Theme.textDark)
                            Text(playerService.sleepTimerService.isActive ? playerService.sleepTimerService.formattedRemainingTime : "Sleep")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(playerService.sleepTimerService.isActive ? Theme.brandGreen : Theme.textDark)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(playerService.sleepTimerService.isActive ? Theme.brandGreen.opacity(0.18) : Theme.surfaceWhite)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Theme.cardBorder, lineWidth: 1))
                    }

                    Spacer()

                    if let book = playerService.currentBook, let currentCh = playerService.currentChapter {
                        Button {
                            showingReader = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "book.pages")
                                    .font(.system(size: 12))
                                Text("Read")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(Theme.brandCyan)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(Theme.surfaceWhite)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Theme.brandCyan.opacity(0.3), lineWidth: 1))
                        }
                        .sheet(isPresented: $showingReader) {
                            BookReaderView(book: book, chapter: currentCh)
                        }
                    }

                    Button {
                        showingChapterSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 12))
                            Text("Chapters")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(Theme.textDark)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Theme.surfaceWhite)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Theme.cardBorder, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 24)
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
        .sheet(isPresented: $showingBookmarkSheet) {
            AddBookmarkSheet(
                timestamp: playerService.currentTime,
                chapterTitle: playerService.currentChapter?.title ?? "Session"
            ) { note in
                playerService.addBookmark(note: note)
            }
        }
    }
}
