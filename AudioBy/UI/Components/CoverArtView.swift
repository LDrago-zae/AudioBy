import SwiftUI

public struct CoverArtView: View {
    public let title: String
    public let author: String
    public let gradientHexes: [String]
    public let coverImageURL: URL?
    public var cornerRadius: CGFloat = 16
    public var shadowRadius: CGFloat = 12

    public init(
        title: String,
        author: String,
        gradientHexes: [String] = ["#4A00E0", "#8E2DE2"],
        coverImageURL: URL? = nil,
        cornerRadius: CGFloat = 16,
        shadowRadius: CGFloat = 12
    ) {
        self.title = title
        self.author = author
        self.gradientHexes = gradientHexes
        self.coverImageURL = coverImageURL
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }

    private var gradientColors: [Color] {
        if gradientHexes.isEmpty {
            return [Theme.brandGreen, Theme.brandCyan]
        }
        return gradientHexes.map { Color(hexString: $0) }
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let imageURL = coverImageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                        case .failure:
                            gradientFallback
                        case .empty:
                            ZStack {
                                gradientFallback
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            }
                        @unknown default:
                            gradientFallback
                        }
                    }
                } else {
                    gradientFallback
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.35), radius: shadowRadius, x: 0, y: 4)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var gradientFallback: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "headphones")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                    Spacer()
                    Image(systemName: "sparkle")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Text(title)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text(author)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(1)
            }
            .padding(12)
        }
    }
}
