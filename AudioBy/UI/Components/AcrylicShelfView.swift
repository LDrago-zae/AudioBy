import SwiftUI

public struct PathCardItem: Identifiable, Sendable {
    public let id: String
    public let number: String
    public let subtitle: String
    public let title: String
    public let gradientColors: [Color]
    public let hasCutout: Bool
    public let backgroundImageName: String?

    public init(
        id: String = UUID().uuidString,
        number: String,
        subtitle: String = "First path",
        title: String,
        gradientColors: [Color],
        hasCutout: Bool = false,
        backgroundImageName: String? = nil
    ) {
        self.id = id
        self.number = number
        self.subtitle = subtitle
        self.title = title
        self.gradientColors = gradientColors
        self.hasCutout = hasCutout
        self.backgroundImageName = backgroundImageName
    }
}

public struct AcrylicShelfView: View {
    public let shelfTitle: String
    public let shelfTint: Color
    public let cards: [PathCardItem]
    public let onSelectCard: (PathCardItem) -> Void

    public init(
        shelfTitle: String,
        shelfTint: Color = Theme.foundationShelfTint,
        cards: [PathCardItem],
        onSelectCard: @escaping (PathCardItem) -> Void = { _ in }
    ) {
        self.shelfTitle = shelfTitle
        self.shelfTint = shelfTint
        self.cards = cards
        self.onSelectCard = onSelectCard
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Tucked Path Cards
            HStack(spacing: 12) {
                ForEach(cards) { card in
                    Button {
                        onSelectCard(card)
                    } label: {
                        PathCardView(card: card)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 22) // Sits down behind the shelf

            // Front Acrylic Glass Bar with Metal Screws
            ZStack {
                // Glass Base
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(shelfTint)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.ultraThinMaterial.opacity(0.85))
                    )
                    .overlay(
                        // Glass reflection border
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.8),
                                        Color.white.opacity(0.2),
                                        Color.black.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)

                // Screws on 4 corners
                HStack {
                    VStack(spacing: 20) {
                        MetallicScrewView(size: 8)
                        MetallicScrewView(size: 8)
                    }
                    Spacer()
                    VStack(spacing: 20) {
                        MetallicScrewView(size: 8)
                        MetallicScrewView(size: 8)
                    }
                }
                .padding(.horizontal, 10)

                // Shelf Label
                Text(shelfTitle)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 1)
            }
            .frame(height: 52)
            .padding(.horizontal, 16)
        }
        .frame(height: 180)
    }
}

// Single Path Card
private struct PathCardView: View {
    let card: PathCardItem

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Background Gradient
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: card.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )

            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text(card.number)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))

                Text(card.subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))

                Spacer()

                Text(card.title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)

            // White Circle cutout badge on bottom right if enabled
            if card.hasCutout {
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .offset(x: 4, y: 4)
            }
        }
        .frame(height: 140)
        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 4)
    }
}
