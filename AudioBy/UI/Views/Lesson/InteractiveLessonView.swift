import SwiftUI

public struct InteractiveLessonView: View {
    @Bindable var playerService = AudioPlayerService.shared
    @Bindable var repository = AudiobookRepository.shared

    @State private var selectedOptionIndex: Int = 0 // 0 = A. Reduce secondary content
    @State private var showingTip: Bool = false
    @State private var isAudioPlaying: Bool = false

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
                                    .foregroundColor(Theme.textDark)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                            }

                            Spacer()

                            VStack(spacing: 2) {
                                Text("Interaction design")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(Theme.textDark)

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
                                    .foregroundColor(showingTip ? Theme.brandGreen : Theme.textDark)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // Top Progress Bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(white: 0.90))
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
                                .foregroundColor(Theme.textDark)

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
                                        playerService.loadAudiobook(book, chapterIndex: 1, autoPlay: true)
                                    } else {
                                        playerService.togglePlayPause()
                                    }
                                }
                            } label: {
                                Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 34, height: 34)
                                    .background(Theme.brandGreen)
                                    .clipShape(Circle())
                            }

                            VStack(alignment: .leading, spacing: 1) {
                                Text("Audio Narration: Progressive Disclosure")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Theme.textDark)
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
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                        .padding(.horizontal, 20)

                        // Question Prompt
                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("You're redesigning this screen.")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(Theme.textDark)
                                Text("What would you change first?")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(Theme.textDark)
                            }

                            // Multiple Choice Options
                            VStack(spacing: 10) {
                                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                                    let isSelected = selectedOptionIndex == index

                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedOptionIndex = index
                                        }
                                    } label: {
                                        HStack {
                                            Text(option)
                                                .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                                                .foregroundColor(isSelected ? .white : Theme.textDark)

                                            Spacer()

                                            if isSelected {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .padding(.horizontal, 18)
                                        .frame(height: 52)
                                        .background(
                                            isSelected
                                                ? AnyShapeStyle(Theme.activeGreenGradient)
                                                : AnyShapeStyle(Color.white)
                                        )
                                        .cornerRadius(14)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(isSelected ? Color.clear : Color(red: 0.88, green: 0.90, blue: 0.92), lineWidth: 1)
                                        )
                                        .shadow(color: isSelected ? Theme.brandGreen.opacity(0.3) : Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 120) // Space for floating dock
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Pro Tip", isPresented: $showingTip) {
                Button("Got it", role: .cancel) {}
            } message: {
                Text("Progressive disclosure prevents cognitive overload by sequencing information across interaction steps rather than displaying everything at once.")
            }
        }
    }
}
