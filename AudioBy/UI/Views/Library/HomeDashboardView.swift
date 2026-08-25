import SwiftUI

public struct HomeDashboardView: View {
    @Bindable var playerService = AudioPlayerService.shared
    @Bindable var repository = AudiobookRepository.shared
    @State private var showingSessionPlayer = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        // Top Header Row
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Good Morning,")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(Theme.textMuted)

                                Text("Michael Kamisado")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Theme.textDark)
                            }

                            Spacer()

                            HStack(spacing: 12) {
                                // Notification Bell
                                Button {
                                    // Notification action
                                } label: {
                                    Image(systemName: "bell")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Theme.textDark)
                                        .frame(width: 44, height: 44)
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                                }

                                // Profile Avatar
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(Color(red: 0.85, green: 0.70, blue: 0.60))
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // Main Learn Score Target Card
                        DotMatrixChartView(score: 97, maxScore: 300) {
                            // On See Details tap
                        }
                        .padding(.horizontal, 20)

                        // Today's 12-min Brief Section
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Today's 12-min Brief")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Theme.textDark)
                                .padding(.horizontal, 20)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    // Card 1: Understand
                                    Button {
                                        startBriefSession()
                                    } label: {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Understand")
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(Theme.textDark)

                                            Text("Progressive disclosure")
                                                .font(.system(size: 13))
                                                .foregroundColor(Theme.textMuted)
                                                .lineLimit(1)

                                            Spacer()

                                            HStack {
                                                Spacer()
                                                Text("4 Min")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(Theme.textMuted)
                                            }
                                        }
                                        .padding(14)
                                        .frame(width: 175, height: 95)
                                        .background(Color.white)
                                        .cornerRadius(16)
                                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    // Card 2: Practice & Apply
                                    Button {
                                        startBriefSession()
                                    } label: {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Practice & Apply")
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(Theme.textDark)

                                            Text("Spot the pattern and refine")
                                                .font(.system(size: 13))
                                                .foregroundColor(Theme.textMuted)
                                                .lineLimit(1)

                                            Spacer()

                                            HStack {
                                                Spacer()
                                                Text("8 Min")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(Theme.textMuted)
                                            }
                                        }
                                        .padding(14)
                                        .frame(width: 175, height: 95)
                                        .background(Color.white)
                                        .cornerRadius(16)
                                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.horizontal, 20)
                            }

                            // Start 12 min session action button
                            Button {
                                startBriefSession()
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color(red: 0.07, green: 0.09, blue: 0.11))
                                        .overlay(
                                            RadialGradient(
                                                colors: [
                                                    Color(red: 0.0, green: 0.85, blue: 0.45).opacity(0.20),
                                                    Color.clear
                                                ],
                                                center: .center,
                                                startRadius: 10,
                                                endRadius: 140
                                            )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                        )

                                    HStack(spacing: 8) {
                                        Image(systemName: "headphones")
                                            .font(.system(size: 15, weight: .bold))
                                        Text("Start 12 min session")
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                }
                                .frame(height: 54)
                                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
                            }
                            .padding(.horizontal, 20)
                        }

                        // Your focus Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your focus")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.textMuted)

                            Text("Interaction Design")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Theme.textDark)
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 100) // Space for floating dock
                    }
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showingSessionPlayer) {
                FullScreenPlayerView()
            }
        }
    }

    private func startBriefSession() {
        if let book = repository.audiobooks.first {
            playerService.loadAudiobook(book, chapterIndex: 0, autoPlay: true)
            showingSessionPlayer = true
        }
    }
}
