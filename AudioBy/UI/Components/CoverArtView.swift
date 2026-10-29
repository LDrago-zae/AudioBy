import SwiftUI

public struct CoverArtView: View {
    public let title: String
    public let author: String
    public let gradientHexes: [String]
    public let coverImageURL: URL?
    public var cornerRadius: CGFloat = 16
    public var shadowRadius: CGFloat = 12
    public var ratio: CGFloat = 1

    public init(
        title: String,
        author: String,
        gradientHexes: [String] = ["#252422", "#403d39"],
        coverImageURL: URL? = nil,
        cornerRadius: CGFloat = 16,
        shadowRadius: CGFloat = 12,
        ratio: CGFloat = 1
    ) {
        self.title = title
        self.author = author
        self.gradientHexes = gradientHexes
        self.coverImageURL = coverImageURL
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.ratio = ratio
    }

    private var gradientColors: [Color] {
        Theme.coverHexes(seed: "\(title)|\(author)", stored: gradientHexes).map { Color(hexString: $0) }
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
                                    .tint(Theme.paper)
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
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Theme.ember)
                    .frame(height: max(4, geometry.size.height * 0.045))
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Theme.stone.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: Theme.ink.opacity(0.22), radius: shadowRadius, x: 0, y: 6)
        }
        .aspectRatio(ratio, contentMode: .fit)
    }

    private var gradientFallback: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "headphones")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.stone)

                Spacer()

                Text(title)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.paper)
                    .lineLimit(2)

                Text(author)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.stone)
                    .lineLimit(1)
            }
            .padding(12)
            .padding(.bottom, 6)
        }
    }
}

struct CatalogPoster: View {
    let book: Audiobook

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CoverArtView(
                title: book.title,
                author: book.author,
                gradientHexes: book.coverGradientColors,
                coverImageURL: book.coverImageURL,
                cornerRadius: 14,
                shadowRadius: 8,
                ratio: 0.72
            )
            .frame(width: 128)

            Text(book.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textDark)
                .lineLimit(2)
                .frame(width: 128, alignment: .leading)

            Text(book.author)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textMuted)
                .lineLimit(1)
                .frame(width: 128, alignment: .leading)

            HStack(spacing: 4) {
                Image(systemName: "headphones")
                    .font(.system(size: 10, weight: .semibold))
                Text(book.formattedTotalDuration)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(Theme.textMuted)
        }
    }
}

struct CatalogListRow<Trailing: View>: View {
    let book: Audiobook
    var showsProgress: Bool = false
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            CoverArtView(
                title: book.title,
                author: book.author,
                gradientHexes: book.coverGradientColors,
                coverImageURL: book.coverImageURL,
                cornerRadius: 10,
                shadowRadius: 4,
                ratio: 0.74
            )
            .frame(width: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textDark)
                    .lineLimit(1)
                Text("by \(book.author)")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textMuted)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Label("Audiobook", systemImage: "headphones")
                    Label(book.formattedTotalDuration, systemImage: "clock")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.textMuted)
                .labelStyle(.titleAndIcon)

                if showsProgress, book.progress > 0 {
                    HStack(spacing: 8) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Theme.stone.opacity(0.45))
                                Capsule()
                                    .fill(Theme.ember)
                                    .frame(width: max(4, geo.size.width * book.progress))
                            }
                        }
                        .frame(height: 4)
                        Text("\(Int(book.progress * 100))%")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.textMuted)
                    }
                }
            }

            Spacer(minLength: 8)
            trailing()
        }
        .padding(12)
        .background(Theme.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Theme.ink.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}
