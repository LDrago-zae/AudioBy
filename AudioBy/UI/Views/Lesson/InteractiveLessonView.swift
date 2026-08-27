import SwiftUI

public struct InteractiveLessonView: View {
    @Bindable var playerService = AudioPlayerService.shared
    @Bindable var repository = AudiobookRepository.shared

    @State private var selectedOptionIndex: Int = 0
    @State private var showingTip: Bool = false

    private let options = [
        "A. Reduce secondary content",
        "B. Reveal advanced options",
        "C. Keep everything visible"
    ]

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // Top Navigation Row
                        HStack {
                            Button {
                                // Back action
                            } label: {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Theme.surfaceWhite)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Theme.cardBorder, lineWidth: 1)
                                    )
                            }

                            Spacer()

                            VStack(spacing: 2) {
                                Text("Interaction design")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)

                                Text("Lesson 04 / 20")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Theme.textMuted)
                            }

                            Spacer()

                            Button {
                                showingTip.toggle()
                            } label: {
                                Image(systemName: "lightbulb")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(showingTip ? Theme.brandGreen : .white)
                                    .frame(width: 44, height: 44)
                                    .background(Theme.surfaceWhite)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Theme.cardBorder, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // Top Progress Bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.12))
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Theme.brandGreen, Theme.brandGreenLight],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * 0.22)
                            }
                        }
                        .frame(height: 6)
                        .padding(.horizontal, 20)

                        // Lesson Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Progressive Disclosure")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)

                            Text("Show only what people need, when they need it.")
                                .font(.system(size: 15))
                                .foregroundColor(Theme.textMuted)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 6)

                        // Visual Wireframe Comparison Card
                        ProgressComparisonView()
                            .padding(.horizontal, 20)

                        // Audio narration mini bar
                        HStack(spacing: 12) {
                            Button {
                                if let book = repository.audiobooks.first {
                                    if playerService.currentBook == nil {
                                        playerService.playAudiobook(book, chapterIndex: 0, autoPlay: true)
                                    } else {
                                        playerService.togglePlayPause()
                                    }
                                }
                            } label: {
                                Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(width: 34, height: 34)
                                    .background(Theme.brandGreen)
                                    .clipShape(Circle())
                            }

                            VStack(alignment: .leading, spacing: 1) {
                                Text("Audio Narration: Progressive Disclosure")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Narrated by Samantha Vance • 3:45")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.textMuted)
                            }

                            Spacer()

                            Image(systemName: "waveform")
                                .font(.system(size: 16))
                                .foregroundColor(playerService.isPlaying ? Theme.brandGreen : Theme.textMuted)
                        }
                        .padding(12)
                        .background(Theme.surfaceWhite)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Theme.cardBorder, lineWidth: 1)
                        )
                        .padding(.horizontal, 20)

                        // Question Section
                        VStack(alignment: .leading, spacing: 14) {
                            Text("What is the primary benefit of progressive disclosure in mobile interfaces?")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .lineSpacing(3)

                            VStack(spacing: 10) {
                                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                                    let isSelected = selectedOptionIndex == index
                                    Button {
                                        selectedOptionIndex = index
                                    } label: {
                                        HStack {
                                            Text(option)
                                                .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                                                .foregroundColor(isSelected ? Theme.brandGreen : .white)

                                            Spacer()

                                            ZStack {
                                                Circle()
                                                    .stroke(isSelected ? Theme.brandGreen : Color.white.opacity(0.3), lineWidth: 2)
                                                    .frame(width: 20, height: 20)

                                                if isSelected {
                                                    Circle()
                                                        .fill(Theme.brandGreen)
                                                        .frame(width: 10, height: 10)
                                                }
                                            }
                                        }
                                        .padding(16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(isSelected ? Theme.brandGreen.opacity(0.12) : Theme.surfaceWhite)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(isSelected ? Theme.brandGreen : Theme.cardBorder, lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }
                        .padding(18)
                        .background(Theme.surfaceWhite)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Theme.cardBorder, lineWidth: 1)
                        )
                        .padding(.horizontal, 20)

                        Spacer(minLength: 120)
                    }
                }
            }
        }
    }
}
