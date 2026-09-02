import SwiftUI

public struct LearningPathView: View {
    @Bindable var playerService = AudioPlayerService.shared
    @Bindable var repository = AudiobookRepository.shared
    @State private var showingPlayerModal = false

    public init() {}

    private let foundationCards = [
        PathCardItem(
            number: "01.",
            subtitle: "First path",
            title: "Visual Design",
            gradientColors: [Color(hexString: "#27AE60"), Color(hexString: "#2ECC71")],
            hasCutout: true
        ),
        PathCardItem(
            number: "02.",
            subtitle: "Second path",
            title: "UIUX Element",
            gradientColors: [Color(hexString: "#F39C12"), Color(hexString: "#E74C3C")],
            hasCutout: false
        ),
        PathCardItem(
            number: "03.",
            subtitle: "Third path",
            title: "User Research",
            gradientColors: [Color(hexString: "#3498DB"), Color(hexString: "#2980B9")],
            hasCutout: true
        )
    ]

    private let buildCards = [
        PathCardItem(
            number: "01.",
            subtitle: "First path",
            title: "Interaction Design",
            gradientColors: [Color(hexString: "#8E44AD"), Color(hexString: "#C0392B")],
            hasCutout: true
        ),
        PathCardItem(
            number: "02.",
            subtitle: "Second path",
            title: "Product Strategy",
            gradientColors: [Color(hexString: "#1A252F"), Color(hexString: "#2C3E50")],
            hasCutout: false
        ),
        PathCardItem(
            number: "03.",
            subtitle: "Third path",
            title: "Design System",
            gradientColors: [Color(hexString: "#1ABC9C"), Color(hexString: "#16A085")],
            hasCutout: false
        )
    ]

    private let proveCards = [
        PathCardItem(
            number: "01.",
            subtitle: "First path",
            title: "Case Study",
            gradientColors: [Color(hexString: "#7F8C8D"), Color(hexString: "#95A5A6")],
            hasCutout: true
        ),
        PathCardItem(
            number: "02.",
            subtitle: "Second path",
            title: "Portfolio Design",
            gradientColors: [Color(hexString: "#2980B9"), Color(hexString: "#34495E")],
            hasCutout: false
        ),
        PathCardItem(
            number: "03.",
            subtitle: "Third path",
            title: "Interview",
            gradientColors: [Color(hexString: "#2C3E50"), Color(hexString: "#111111")],
            hasCutout: false
        )
    ]

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Top Header
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Your path becoming,")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(Theme.textMuted)

                                Text("Product designer")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(Theme.textDark)
                            }

                            Spacer()

                            Button {
                                // More options
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Theme.textDark)
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

                        // Overall Progress Card
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Overall progress")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.textMuted)

                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("8")
                                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                                    .foregroundColor(Theme.textDark)

                                Text("/14")
                                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                                    .foregroundColor(Theme.textMuted)

                                Text("Skills developed")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Theme.textDark)
                                    .padding(.leading, 6)
                            }

                            // 14 Beaded LED Progress Indicators
                            HStack(spacing: 6) {
                                ForEach(0..<14, id: \.self) { index in
                                    let isCompleted = index < 8
                                    Circle()
                                        .fill(isCompleted ? Theme.brandGreen : Theme.cardBorder)
                                        .frame(width: 14, height: 14)
                                        .shadow(color: isCompleted ? Theme.brandGreen.opacity(0.5) : .clear, radius: 3)
                                }
                            }
                            .padding(.vertical, 2)

                            Text("Personalized to your skill and goals")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.textMuted)
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

                        // 3D Acrylic Shelves with Lesson Cards
                        VStack(spacing: 28) {
                            AcrylicShelfView(
                                shelfTitle: "Foundation lesson",
                                shelfTint: Theme.foundationShelfTint,
                                cards: foundationCards
                            ) { card in
                                playLesson(for: card)
                            }

                            AcrylicShelfView(
                                shelfTitle: "Build lesson",
                                shelfTint: Theme.buildShelfTint,
                                cards: buildCards
                            ) { card in
                                playLesson(for: card)
                            }

                            AcrylicShelfView(
                                shelfTitle: "Prove lesson",
                                shelfTint: Theme.proveShelfTint,
                                cards: proveCards
                            ) { card in
                                playLesson(for: card)
                            }
                        }
                        .padding(.top, 10)

                        Spacer(minLength: 120)
                    }
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showingPlayerModal) {
                FullScreenPlayerView()
            }
        }
    }

    private func playLesson(for card: PathCardItem) {
        if let book = repository.audiobooks.first {
            playerService.playAudiobook(book, chapterIndex: 0, autoPlay: true)
            showingPlayerModal = true
        }
    }
}
