import SwiftUI
import AVKit

public struct FullScreenPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var playerService = AudioPlayerService.shared

    @State private var showingSpeedSheet = false
    @State private var showingSleepTimerSheet = false
    @State private var showingChapterSheet = false
    @State private var showingBookmarkSheet = false
    @State private var sleepTimer = SleepTimerService()

    public init() {}

    public var body: some View {
        ZStack {
            Theme.appBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                // Top Nav
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Theme.textDark)
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text("AUDIO SESSION")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.brandGreen)
                            .tracking(1.2)
                        Text(playerService.currentBook?.title ?? "Session")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.textDark)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        showingBookmarkSheet = true
                    } label: {
                        Image(systemName: "bookmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Theme.textDark)
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)

                Spacer(minLength: 10)

                // Large Matrix Artwork Card
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(red: 0.06, green: 0.08, blue: 0.10))
                        .overlay(
                            RadialGradient(
                                colors: [
                                    Theme.brandGreen.opacity(0.30),
                                    Color.clear
                                ],
                                center: .topTrailing,
                                startRadius: 10,
                                endRadius: 200
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "headphones")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Theme.brandGreen)
                            Spacer()
                            Text("12-min Brief")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.12))
                                .clipShape(Capsule())
                        }

                        Spacer()

                        Text(playerService.currentChapter?.title ?? "Progressive Disclosure")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(2)

                        Text("Narrated by \(playerService.currentBook?.narrator ?? "Samantha Vance")")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))

                        // Waveform visualizer
                        WaveformVisualizer(isPlaying: playerService.isPlaying, barCount: 26, activeColor: Theme.brandGreen)
                            .padding(.top, 6)
                    }
                    .padding(24)
                }
                .frame(maxWidth: 320, maxHeight: 300)
                .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 8)
                .padding(.horizontal, 24)

                Spacer(minLength: 10)

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
                HStack(spacing: 24) {
                    // 15s Jump Back
                    Button {
                        playerService.jump(by: -15)
                    } label: {
                        Image(systemName: "gobackward.15")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.textDark)
                            .frame(width: 48, height: 48)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                    }

                    // Previous Chapter
                    Button {
                        playerService.previousChapter()
                    } label: {
                        Image(systemName: "backward.end.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.textDark)
                    }

                    // Big Play / Pause Button
                    Button {
                        playerService.togglePlayPause()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Theme.activeGreenGradient)
                                .frame(width: 74, height: 74)
                                .shadow(color: Theme.brandGreen.opacity(0.4), radius: 14, x: 0, y: 6)

                            Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: playerService.isPlaying ? 0 : 2)
                        }
                    }

                    // Next Chapter
                    Button {
                        playerService.nextChapter()
                    } label: {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.textDark)
                    }

                    // 30s Jump Forward
                    Button {
                        playerService.jump(by: 30)
                    } label: {
                        Image(systemName: "goforward.30")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.textDark)
                            .frame(width: 48, height: 48)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                    }
                }
                .padding(.vertical, 8)

                // Bottom Tool Bar (Speed, Sleep, Chapters)
                HStack(spacing: 12) {
                    Button {
                        showingSpeedSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                                .font(.system(size: 13))
                            Text(playerService.playbackSpeed.shortTitle)
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(Theme.textDark)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                    }

                    Button {
                        showingSleepTimerSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: sleepTimer.isActive ? "moon.stars.fill" : "moon")
                                .font(.system(size: 13))
                                .foregroundColor(sleepTimer.isActive ? Theme.brandGreen : Theme.textDark)
                            Text(sleepTimer.isActive ? sleepTimer.formattedRemainingTime : "Sleep")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(sleepTimer.isActive ? Theme.brandGreen : Theme.textDark)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(sleepTimer.isActive ? Theme.brandGreen.opacity(0.12) : Color.white)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                    }

                    Spacer()

                    Button {
                        showingChapterSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 13))
                            Text("Chapters")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(Theme.textDark)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showingSpeedSheet) {
            SpeedPickerSheet(currentSpeed: playerService.playbackSpeed) { speed in
                playerService.setSpeed(speed)
            }
        }
        .sheet(isPresented: $showingSleepTimerSheet) {
            SleepTimerSheet(activeOption: sleepTimer.selectedOption) { option in
                sleepTimer.setTimer(
                    option: option,
                    remainingChapterTime: playerService.remainingChapterTime
                ) {
                    playerService.pause()
                }
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
