import SwiftUI
import UIKit

// MARK: - Dynamic Hex UIColor Extension
extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: CGFloat(a) / 255.0
        )
    }

    convenience init(hex: String) {
        self.init(hexString: hex)
    }
}

/// Japanese editorial design system tokens from Kinetic Shiori / Komorebi.
/// Fully dynamic dual-mode system supporting authentic Washi Paper (Light) and Sumi-e Ink / OLED Charcoal (Dark).
public enum MangaTheme {
    // MARK: - Dynamic Color Resolver
    public static func dynamic(light: String, dark: String) -> Color {
        Color(UIColor { trait in
            let isDark: Bool
            if trait.userInterfaceStyle == .unspecified {
                isDark = UserDefaults.standard.object(forKey: "isDarkMode") as? Bool ?? true
            } else {
                isDark = trait.userInterfaceStyle == .dark
            }
            return isDark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }

    public static func dynamic(light: Color, dark: Color) -> Color {
        Color(UIColor { trait in
            let isDark: Bool
            if trait.userInterfaceStyle == .unspecified {
                isDark = UserDefaults.standard.object(forKey: "isDarkMode") as? Bool ?? true
            } else {
                isDark = trait.userInterfaceStyle == .dark
            }
            return isDark ? UIColor(dark) : UIColor(light)
        })
    }

    // MARK: - Surfaces (Washi Paper & Sumi Ink Canvas)
    /// Main canvas surface (#FCF9EF in Light, #141311 in Dark)
    public static var surface: Color {
        dynamic(light: "#FCF9EF", dark: "#141311")
    }

    /// Dim surface (#DCDAD0 in Light, #0D0C0A in Dark)
    public static var surfaceDim: Color {
        dynamic(light: "#DCDAD0", dark: "#0D0C0A")
    }

    /// Low card elevation (#F6F4EA in Light, #1C1B17 in Dark)
    public static var surfaceLow: Color {
        dynamic(light: "#F6F4EA", dark: "#1C1B17")
    }

    /// Container cards (#F1EEE4 in Light, #24231E in Dark)
    public static var surfaceContainer: Color {
        dynamic(light: "#F1EEE4", dark: "#24231E")
    }

    /// High elevation buttons and chips (#EBE8DE in Light, #2F2D26 in Dark)
    public static var surfaceHigh: Color {
        dynamic(light: "#EBE8DE", dark: "#2F2D26")
    }

    /// Highest elevation and progress tracks (#E5E2D9 in Light, #393730 in Dark)
    public static var surfaceHighest: Color {
        dynamic(light: "#E5E2D9", dark: "#393730")
    }

    // MARK: - Inks & Text
    /// Primary text (#1C1C16 charcoal in Light, #F8F5EC ivory in Dark)
    public static var ink: Color {
        dynamic(light: "#1C1C16", dark: "#F8F5EC")
    }

    /// Secondary heading/accent text (#594139 in Light, #DDD8CD in Dark)
    public static var inkVariant: Color {
        dynamic(light: "#594139", dark: "#DDD8CD")
    }

    /// Subtitles, captions, metadata (#615E59 in Light, #A9A499 in Dark)
    public static var secondary: Color {
        dynamic(light: "#615E59", dark: "#A9A499")
    }

    /// Muted timestamps (#79746A in Light, #7D786F in Dark)
    public static var tertiary: Color {
        dynamic(light: "#79746A", dark: "#7D786F")
    }

    /// Subtle borders and dividers
    public static var hairline: Color {
        dynamic(
            light: Color(hex: "#CCC5B9").opacity(0.45),
            dark: Color.white.opacity(0.12)
        )
    }

    public static var outline: Color {
        dynamic(light: "#8D7168", dark: "#9F8278")
    }

    // MARK: - Vermilion / Shu-iro Accents (Traditional Cinnabar)
    public static var vermilion: Color {
        dynamic(light: "#EB5E28", dark: "#FF6B35")
    }

    public static var vermilionDeep: Color {
        dynamic(light: "#A73400", dark: "#CC4811")
    }

    public static var vermilionContainer: Color {
        dynamic(light: "#CC4811", dark: "#4D1B07")
    }

    public static var vermilionFixed: Color {
        dynamic(light: "#FFDBCF", dark: "#3D1A0E")
    }

    // MARK: - Reader Canvas (OLED & Dark)
    public static let readerDark = Color(hex: "#141311")
    public static let readerCard = Color(hex: "#1E1D19")
    public static let readerElevated = Color(hex: "#282621")
    public static let readerOverlay = Color(hex: "#33312B")
    public static let readerIvory = Color(hex: "#FCF9EF")

    // MARK: - Shadows & Radii
    public static let cardRadius: CGFloat = 12
    public static let buttonRadius: CGFloat = 14
    public static let pillRadius: CGFloat = 9999

    public static var cardShadow: Color {
        dynamic(
            light: Color(hex: "#252422").opacity(0.06),
            dark: Color.black.opacity(0.45)
        )
    }
}

// MARK: - Manga View Modifiers & Components
public struct MangaBadge: View {
    public let text: String
    public var isAccent: Bool = false

    public init(_ text: String, isAccent: Bool = false) {
        self.text = text
        self.isAccent = isAccent
    }

    public var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(0.6)
            .foregroundStyle(isAccent ? .white : MangaTheme.ink)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                isAccent ? MangaTheme.vermilion : MangaTheme.surfaceHigh,
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(isAccent ? Color.clear : MangaTheme.hairline, lineWidth: 1)
            )
    }
}

public struct MangaCoverCard: View {
    public let series: MangaSeries
    public var progress: Double? = nil
    public var badgeText: String? = nil

    public init(series: MangaSeries, progress: Double? = nil, badgeText: String? = nil) {
        self.series = series
        self.progress = progress
        self.badgeText = badgeText
    }

    private var resolvedCoverURL: URL? {
        guard let raw = series.coverURL?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
        if raw.hasPrefix("http://") || raw.hasPrefix("https://") { return URL(string: raw) }
        return CBZImporter.resolvedPageURL(raw)
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            // 2:3 Cover artwork
            GeometryReader { geo in
                ZStack(alignment: .topTrailing) {
                    if let url = resolvedCoverURL {
                        if url.isFileURL, let uiImage = UIImage(contentsOfFile: url.path) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                        } else {
                            CachedAsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: geo.size.width, height: geo.size.height)
                                        .clipped()
                                case .failure:
                                    fallbackArt(geo)
                                case .empty:
                                    ZStack {
                                        MangaTheme.surfaceContainer
                                        ProgressView().tint(MangaTheme.vermilion)
                                    }
                                @unknown default:
                                    fallbackArt(geo)
                                }
                            }
                        }
                    } else {
                        fallbackArt(geo)
                    }

                    // Top badge overlay
                    if let badge = badgeText ?? (series.status == "ONGOING" ? "MANGA" : series.status) {
                        MangaBadge(badge)
                            .padding(6)
                    }
                }
            }
            .aspectRatio(2/3, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous)
                    .stroke(MangaTheme.hairline, lineWidth: 1)
            )
            .shadow(color: MangaTheme.cardShadow, radius: 8, x: 0, y: 3)

            // Progress bar overlay along bottom edge
            if let p = progress, p > 0 {
                GeometryReader { geo in
                    VStack {
                        Spacer()
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.black.opacity(0.45))
                                .frame(height: 3)
                            Rectangle()
                                .fill(MangaTheme.vermilion)
                                .frame(width: geo.size.width * CGFloat(min(1.0, p)), height: 3)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
            }
        }
    }

    private func fallbackArt(_ geo: GeometryProxy) -> some View {
        ZStack {
            LinearGradient(
                colors: [MangaTheme.readerCard, MangaTheme.readerDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 8) {
                Image(systemName: "book.pages")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(MangaTheme.vermilion)
                Text(series.title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 6)
            }
        }
        .frame(width: geo.size.width, height: geo.size.height)
    }
}

// MARK: - Komorebi Book Card for Audiobooks & Novels
public struct KomorebiBookCard: View {
    public let book: Audiobook
    public var badgeText: String? = nil
    public var showProgress: Bool = true

    public init(book: Audiobook, badgeText: String? = nil, showProgress: Bool = true) {
        self.book = book
        self.badgeText = badgeText
        self.showProgress = showProgress
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottom) {
                // 2:3 Ratio Artwork
                CoverArtView(
                    title: book.title,
                    author: book.author,
                    gradientHexes: book.coverGradientColors,
                    coverImageURL: book.coverImageURL,
                    cornerRadius: MangaTheme.cardRadius,
                    shadowRadius: 6,
                    ratio: 2/3
                )
                .aspectRatio(2/3, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous)
                        .stroke(MangaTheme.hairline, lineWidth: 1)
                )
                .shadow(color: MangaTheme.cardShadow, radius: 8, x: 0, y: 3)

                // Top Badge Overlay
                VStack {
                    HStack {
                        Spacer()
                        let label = badgeText ?? (book.gutenbergId != nil ? "NOVEL" : "AUDIOBOOK")
                        MangaBadge(label)
                            .padding(6)
                    }
                    Spacer()
                }

                // Progress Bar Overlay
                if showProgress && book.progress > 0 {
                    GeometryReader { geo in
                        VStack {
                            Spacer()
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.black.opacity(0.45))
                                    .frame(height: 3.5)
                                Rectangle()
                                    .fill(MangaTheme.vermilion)
                                    .frame(width: geo.size.width * CGFloat(min(1.0, book.progress)), height: 3.5)
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
                }
            }

            // Title & Author/Narrator Meta
            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)
                    .lineLimit(1)

                Text(book.narrator.isEmpty || book.narrator == "Narrator" ? book.author : "\(book.author) • \(book.narrator)")
                    .font(.system(size: 11))
                    .foregroundStyle(MangaTheme.secondary)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Komorebi Section Header
public struct KomorebiSectionHeader: View {
    public let title: String
    public var japaneseSub: String? = nil
    public var actionText: String? = nil
    public var action: (() -> Void)? = nil

    public init(title: String, japaneseSub: String? = nil, actionText: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.japaneseSub = japaneseSub
        self.actionText = actionText
        self.action = action
    }

    public var body: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                if let sub = japaneseSub {
                    Text(sub.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(MangaTheme.vermilion)
                }
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)
            }

            Spacer()

            if let actionText = actionText {
                Button {
                    action?()
                } label: {
                    Text(actionText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MangaTheme.vermilion)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Komorebi Streak Widget
public struct KomorebiStreakWidget: View {
    public var streakDays: Int = 14
    public var minutesToday: Int = 48
    public var goalMinutes: Int = 60

    public init(streakDays: Int = 14, minutesToday: Int = 48, goalMinutes: Int = 60) {
        self.streakDays = streakDays
        self.minutesToday = minutesToday
        self.goalMinutes = goalMinutes
    }

    private var percentage: Double {
        guard goalMinutes > 0 else { return 0 }
        return min(1.0, Double(minutesToday) / Double(goalMinutes))
    }

    public var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(MangaTheme.vermilionFixed)
                    .frame(width: 44, height: 44)
                Image(systemName: "flame.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(MangaTheme.vermilion)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(streakDays)-Day Literary Streak")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)
                Text("\(minutesToday) mins today • Goal: \(goalMinutes) mins")
                    .font(.system(size: 12))
                    .foregroundStyle(MangaTheme.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(percentage * 100))%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(MangaTheme.vermilion)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(MangaTheme.surfaceHighest)
                        .frame(width: 54, height: 6)
                    Capsule()
                        .fill(MangaTheme.vermilion)
                        .frame(width: 54 * CGFloat(percentage), height: 6)
                }
            }
        }
        .padding(14)
        .background(MangaTheme.surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous)
                .stroke(MangaTheme.hairline, lineWidth: 1)
        )
        .shadow(color: MangaTheme.cardShadow, radius: 8, x: 0, y: 3)
        .padding(.horizontal, 20)
    }
}
