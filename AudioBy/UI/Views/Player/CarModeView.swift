import SwiftUI

public struct CarModeView: View {
    @Bindable var playerService = AudioPlayerService.shared
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 28) {
                // Top Bar: Exit Car Mode & Chapter Indicator
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .bold))
                            Text("Exit Car Mode")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                    }

                    Spacer()

                    Image(systemName: "car.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Theme.brandGreen)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Book & Chapter Info (High Contrast Large Typography)
                VStack(spacing: 12) {
                    Text(playerService.currentBook?.title ?? "Audiobook")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 20)

                    Text(playerService.currentChapter?.title ?? "Chapter")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Theme.brandGreenLight)
                        .lineLimit(1)

                    Text(playerService.currentBook?.author ?? "")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.7))
                }

                Spacer()

                // Large Time Scrubber
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 12)

                            let progress = playerService.duration > 0 ? (playerService.currentTime / playerService.duration) : 0
                            Capsule()
                                .fill(Theme.brandGreen)
                                .frame(width: max(0, CGFloat(progress) * geo.size.width), height: 12)
                        }
                    }
                    .frame(height: 12)
                    .padding(.horizontal, 24)

                    HStack {
                        Text(formatSeconds(playerService.currentTime))
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))

                        Spacer()

                        Text("-" + formatSeconds(max(0, playerService.duration - playerService.currentTime)))
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()

                // Giant Drive Controls (Audible / Spotify Car Mode Style)
                HStack(spacing: 24) {
                    // Skip Back 15s
                    Button {
                        playerService.jump(by: -15)
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "gobackward.15")
                                .font(.system(size: 38, weight: .bold))
                            Text("15s")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(width: 88, height: 88)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                    }

                    // Giant Play / Pause Button
                    Button {
                        playerService.togglePlayPause()
                        let generator = UIImpactFeedbackGenerator(style: .heavy)
                        generator.impactOccurred()
                    } label: {
                        Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 110, height: 110)
                            .background(Theme.brandGreen)
                            .clipShape(Circle())
                            .shadow(color: Theme.brandGreen.opacity(0.4), radius: 12, x: 0, y: 4)
                    }

                    // Skip Forward 30s
                    Button {
                        playerService.jump(by: 30)
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "goforward.30")
                                .font(.system(size: 38, weight: .bold))
                            Text("30s")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(width: 88, height: 88)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                // Bookmark & Chapter Buttons
                HStack(spacing: 20) {
                    Button {
                        playerService.previousChapter()
                    } label: {
                        HStack {
                            Image(systemName: "backward.end.fill")
                            Text("Prev Chapter")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                    }

                    Button {
                        playerService.addBookmark(note: "Saved in Car Mode")
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    } label: {
                        HStack {
                            Image(systemName: "bookmark.fill")
                            Text("Bookmark")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.brandGreenLight)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                    }

                    Button {
                        playerService.nextChapter()
                    } label: {
                        HStack {
                            Text("Next")
                            Image(systemName: "forward.end.fill")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }

    private func formatSeconds(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds))
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
