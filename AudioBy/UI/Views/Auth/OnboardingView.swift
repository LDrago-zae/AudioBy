import SwiftUI

private struct OnboardingPage: Identifiable {
    let id: Int
    let symbol: String
    let title: String
    let body: String
}

public struct OnboardingView: View {
    var onFinished: () -> Void

    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            symbol: "books.vertical.fill",
            title: "A library that stays with you",
            body: "Browse and search tens of thousands of public-domain titles from a catalog stored on your device. No waiting on a live listing to start exploring."
        ),
        OnboardingPage(
            id: 1,
            symbol: "play.circle.fill",
            title: "Listen the way you actually read",
            body: "Chapter audio, offline downloads, and on-device narration for books that never had a human recording. Your place is saved when you come back."
        ),
        OnboardingPage(
            id: 2,
            symbol: "waveform",
            title: "Go further when you want to",
            body: "Import a PDF, keep more titles offline, or unlock studio voices on Premium. The catalog itself stays free."
        )
    ]

    public var body: some View {
        ZStack {
            Theme.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    if page < pages.count - 1 {
                        Button("Skip") { finish() }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Theme.textMuted)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .frame(height: 44)

                TabView(selection: $page) {
                    ForEach(pages) { item in
                        VStack(spacing: 28) {
                            Spacer(minLength: 12)
                            ZStack {
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .fill(Theme.brandGreen)
                                    .frame(width: 132, height: 132)
                                Image(systemName: item.symbol)
                                    .font(.system(size: 52, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                            VStack(spacing: 12) {
                                Text(item.title)
                                    .font(.system(size: 28, weight: .heavy))
                                    .foregroundColor(Theme.textDark)
                                    .multilineTextAlignment(.center)
                                Text(item.body)
                                    .font(.system(size: 16))
                                    .foregroundColor(Theme.textMuted)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(3)
                            }
                            .padding(.horizontal, 8)
                            Spacer()
                        }
                        .padding(.horizontal, 28)
                        .tag(item.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(pages) { item in
                        Capsule()
                            .fill(item.id == page ? Theme.brandGreen : Theme.cardBorder)
                            .frame(width: item.id == page ? 22 : 8, height: 8)
                    }
                }
                .padding(.bottom, 24)

                AuthPrimaryButton(
                    title: page == pages.count - 1 ? "Get started" : "Continue"
                ) {
                    if page == pages.count - 1 {
                        finish()
                    } else {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            page += 1
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: AuthService.onboardingKey)
        onFinished()
    }
}
