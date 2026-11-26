import SwiftUI
import AVFoundation

public enum NovelTheme: String, CaseIterable, Identifiable {
    case ivory = "Paper Ivory"
    case sepia = "Sepia Cream"
    case charcoal = "Warm Charcoal"
    case oled = "OLED Black"

    public var id: String { rawValue }

    public var background: Color {
        switch self {
        case .ivory: return Color(hex: "#FCF9EF")
        case .sepia: return Color(hex: "#F4EEDD")
        case .charcoal: return Color(hex: "#252422")
        case .oled: return Color.black
        }
    }

    public var text: Color {
        switch self {
        case .ivory: return Color(hex: "#1C1C16")
        case .sepia: return Color(hex: "#382D24")
        case .charcoal: return Color(hex: "#F4F1E7")
        case .oled: return Color(hex: "#FCF9EF")
        }
    }

    public var mutedText: Color {
        switch self {
        case .ivory: return Color(hex: "#615E59")
        case .sepia: return Color(hex: "#7A6B5D")
        case .charcoal: return Color(hex: "#A8A399")
        case .oled: return Color(hex: "#99958C")
        }
    }
}

public enum NovelTypeface: String, CaseIterable, Identifiable {
    case serif = "Mincho Serif"
    case sans = "Manrope"
    case system = "Inter Sans"

    public var id: String { rawValue }

    public var fontDesign: Font.Design {
        switch self {
        case .serif: return .serif
        case .sans: return .rounded
        case .system: return .default
        }
    }
}

public struct NovelReaderView: View {
    @Environment(\.dismiss) private var dismiss

    public var bookTitle: String = "The Memory Police"
    public var chapterTitle: String = "Chapter IV: The Disappearance of Ribbons"

    @AppStorage("isDarkMode") private var isDarkMode: Bool = true
    @State private var novelTheme: NovelTheme = .charcoal
    @State private var typeface: NovelTypeface = .serif
    @State private var fontSize: CGFloat = 17
    @State private var lineSpacing: CGFloat = 8
    @State private var marginPadding: CGFloat = 20
    @State private var showHUD: Bool = true
    @State private var showAppearanceSheet: Bool = false
    @State private var isBookmarked: Bool = false
    @State private var audioDramaSync: Bool = false
    @State private var currentPage: Int = 148
    @State private var totalPages: Int = 230
    @State private var brightness: Double = 0.85
    @State private var showHighlightNote: Bool = true

    @Bindable private var playerService = AudioPlayerService.shared

    public init(bookTitle: String = "The Memory Police", chapterTitle: String = "Chapter IV: The Disappearance of Ribbons") {
        self.bookTitle = bookTitle
        self.chapterTitle = chapterTitle
        let isDark = UserDefaults.standard.object(forKey: "isDarkMode") as? Bool ?? true
        _novelTheme = State(initialValue: isDark ? .charcoal : .ivory)
    }

    public var body: some View {
        ZStack {
            novelTheme.background.ignoresSafeArea()

            // Immersive Novel Content
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    runningHeader

                    articleContent

                    pageEndMarker

                    Spacer(minLength: 120)
                }
                .duoReadableContainer(maxWidth: 700)
                .padding(.horizontal, marginPadding)
                .padding(.top, 70)
            }
            .pageTapScroll {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    showHUD.toggle()
                }
            }

            // Top Floating HUD
            if showHUD {
                VStack(spacing: 0) {
                    topHUD
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Bottom Floating HUD
            if showHUD {
                VStack(spacing: 0) {
                    Spacer()
                    bottomHUD
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showAppearanceSheet) {
            appearanceSheet
                .presentationDetents([.fraction(0.55), .medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Running Header
    private var runningHeader: some View {
        HStack {
            Text(bookTitle.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(novelTheme.mutedText)
            Spacer()
            Text("CH. 4")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(novelTheme.mutedText)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Article Content with Drop Cap & Japanese Illustrations
    private var articleContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Part badge & title
            VStack(spacing: 6) {
                Text("— PART ONE —")
                    .font(.system(size: 11, weight: .bold, design: typeface.fontDesign))
                    .tracking(2.0)
                    .foregroundStyle(MangaTheme.vermilion)

                Text("CHAPTER IV")
                    .font(.system(size: 26, weight: .bold, design: typeface.fontDesign))
                    .foregroundStyle(novelTheme.text)

                Text("The Disappearance of Ribbons")
                    .font(.system(size: 14, weight: .medium, design: typeface.fontDesign))
                    .italic()
                    .foregroundStyle(novelTheme.mutedText)

                HStack(spacing: 6) {
                    Circle().fill(MangaTheme.vermilion).frame(width: 4, height: 4)
                    Circle().fill(MangaTheme.vermilion.opacity(0.6)).frame(width: 4, height: 4)
                    Circle().fill(MangaTheme.vermilion.opacity(0.3)).frame(width: 4, height: 4)
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 10)

            // Paragraph 1 with Drop Cap 'I'
            HStack(alignment: .top, spacing: 10) {
                Text("I")
                    .font(.system(size: 58, weight: .bold, design: .serif))
                    .foregroundStyle(novelTheme.text)
                    .frame(width: 42, height: 50, alignment: .topLeading)

                Text("n the morning, the disappearance was quiet. It was ribbons. Delicate emerald and vermilion ribbons fluttered from open windows toward the river, carried away into the cold dawn air without a whisper or a protest.")
                    .font(.system(size: fontSize, design: typeface.fontDesign))
                    .lineSpacing(lineSpacing)
                    .foregroundStyle(novelTheme.text)
            }

            Text("They glided between telegraph poles and across cedar gables like unspooling memories, dissolving into the mist. I had stepped out onto the balcony while the kettle still whistled faintly upon the cast-iron stove.")
                .font(.system(size: fontSize, design: typeface.fontDesign))
                .lineSpacing(lineSpacing)
                .foregroundStyle(novelTheme.text)

            // Highlighted passage with interactive tooltip
            VStack(alignment: .leading, spacing: 6) {
                if showHighlightNote {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil.line")
                            .font(.system(size: 11))
                            .foregroundStyle(MangaTheme.vermilion)
                        Text("1 note • 32 reader highlights")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(MangaTheme.readerCard, in: Capsule())
                    .shadow(color: Color.black.opacity(0.2), radius: 6, y: 2)
                }

                Text("My neighbor, an elderly milliner whose fingers were permanently dyed indigo from thread, leaned against her railing with empty palms upturned to the grey sky. She smiled faintly, not with sorrow, but with the hollow tranquility of someone who has dropped an old coin into very deep water.")
                    .font(.system(size: fontSize, design: typeface.fontDesign))
                    .lineSpacing(lineSpacing)
                    .foregroundStyle(novelTheme.text)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(MangaTheme.vermilionFixed.opacity(0.25))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(MangaTheme.vermilion.opacity(0.4), lineWidth: 1)
                    )
            }

            // Inline Woodblock Print Illustration Card
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        LinearGradient(
                            colors: [Color(hex: "#DDD6C7"), Color(hex: "#C5BBAA")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        VStack(spacing: 8) {
                            Image(systemName: "mountain.2.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(Color(hex: "#7D7162"))
                            Text("霧が川を包み、朱色の帯が夜明けの町を彷徨う。")
                                .font(.system(size: 12, design: .serif))
                                .foregroundStyle(Color(hex: "#4A4237"))
                        }
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    // Japanese Red Stamp / Seal
                    Text("印\n朝霧")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(MangaTheme.vermilion, in: RoundedRectangle(cornerRadius: 4))
                        .padding(8)
                }

                HStack {
                    Text("Fig. 4.1 — The River at Dawn")
                        .font(.system(size: 12, weight: .medium, design: typeface.fontDesign))
                        .foregroundStyle(novelTheme.mutedText)
                    Spacer()
                    MangaBadge("ORIGINAL WOODBLOCK PRINT")
                }
            }
            .padding(.vertical, 8)

            Text("“Do you remember what they were for?” she asked as I passed her gate an hour later. Her voice held neither alarm nor curiosity, merely the rhythmic calm of seasonal rain.")
                .font(.system(size: fontSize, design: typeface.fontDesign))
                .lineSpacing(lineSpacing)
                .foregroundStyle(novelTheme.text)

            Text("I paused, searching the small wooden chest inside my mind where names, uses, and textures were usually filed. But the compartment was already vacant, scrubbed smooth like driftwood stranded on gravel. “No,” I confessed, wrapping my woolen shawl tighter against the chill. “I only recall they were soft.”")
                .font(.system(size: fontSize, design: typeface.fontDesign))
                .lineSpacing(lineSpacing)
                .foregroundStyle(novelTheme.text)
        }
    }

    private var pageEndMarker: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Rectangle().fill(novelTheme.mutedText.opacity(0.3)).frame(height: 1)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(MangaTheme.vermilion)
                Rectangle().fill(novelTheme.mutedText.opacity(0.3)).frame(height: 1)
            }
            .padding(.horizontal, 40)

            Text("Page \(currentPage) of \(totalPages) • \(bookTitle)")
                .font(.system(size: 11, design: typeface.fontDesign))
                .foregroundStyle(novelTheme.mutedText)
        }
        .padding(.top, 24)
    }

    // MARK: - Top Floating HUD
    private var topHUD: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.12), in: Circle())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(bookTitle)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(chapterTitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.75))
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    isBookmarked.toggle()
                } label: {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 15))
                        .foregroundStyle(isBookmarked ? MangaTheme.vermilion : .white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.12), in: Circle())
                }

                Button {
                    showAppearanceSheet = true
                } label: {
                    Text("Aa")
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.12), in: Circle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 50)
        .padding(.bottom, 12)
        .background(
            MangaTheme.readerCard.opacity(0.94)
                .ignoresSafeArea(edges: .top)
        )
        .overlay(Divider().background(Color.white.opacity(0.1)), alignment: .bottom)
    }

    // MARK: - Bottom Floating HUD
    private var bottomHUD: some View {
        VStack(spacing: 10) {
            // Chapter Progress Bar
            HStack {
                Button {
                    currentPage = max(1, currentPage - 10)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 10))
                        Text("Ch. 3")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(.white)
                }

                Spacer()

                Text("Page \(currentPage) of \(totalPages) • Ch. 4 (64%)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(MangaTheme.vermilion)

                Spacer()

                Button {
                    currentPage = min(totalPages, currentPage + 10)
                } label: {
                    HStack(spacing: 4) {
                        Text("Ch. 5")
                            .font(.system(size: 12, weight: .bold))
                        Image(systemName: "forward.fill")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 16)

            // Precision Scrubber
            Slider(
                value: Binding<Double>(
                    get: { Double(currentPage) },
                    set: { currentPage = Int($0) }
                ),
                in: 1...Double(totalPages),
                step: 1
            )
            .tint(MangaTheme.vermilion)
            .padding(.horizontal, 16)

            // Secondary Quick Tool Dock
            HStack(spacing: 12) {
                // Audio Drama Sync Button
                Button {
                    audioDramaSync.toggle()
                    if audioDramaSync, let book = AudiobookRepository.shared.audiobooks.first {
                        playerService.playAudiobook(book, chapterIndex: 0)
                    } else {
                        playerService.pause()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(audioDramaSync ? MangaTheme.vermilion : Color.gray)
                            .frame(width: 6, height: 6)
                        Text(audioDramaSync ? "Audio Drama Active" : "Audio Drama Sync")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        audioDramaSync ? MangaTheme.vermilion.opacity(0.3) : Color.white.opacity(0.1),
                        in: Capsule()
                    )
                    .overlay(
                        Capsule().stroke(audioDramaSync ? MangaTheme.vermilion : Color.white.opacity(0.2), lineWidth: 1)
                    )
                }

                Spacer()

                Button {
                    showAppearanceSheet = true
                } label: {
                    Image(systemName: "textformat.size")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.12), in: Circle())
                }

                Button {
                    brightness = brightness > 0.5 ? 0.3 : 0.85
                } label: {
                    Image(systemName: brightness > 0.5 ? "sun.max.fill" : "sun.min")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.12), in: Circle())
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            MangaTheme.readerCard.opacity(0.95)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Typography & Customization Sheet
    private var appearanceSheet: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Typography & Appearance")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)
                Spacer()
                Button {
                    showAppearanceSheet = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(MangaTheme.secondary)
                }
            }

            Divider().background(MangaTheme.hairline)

            // Themes
            VStack(alignment: .leading, spacing: 10) {
                Text("Canvas Paper Tone")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)

                HStack(spacing: 10) {
                    ForEach(NovelTheme.allCases) { theme in
                        let isSel = novelTheme == theme
                        Button {
                            novelTheme = theme
                        } label: {
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(theme.background)
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle().stroke(isSel ? MangaTheme.vermilion : MangaTheme.hairline, lineWidth: 2)
                                    )
                                Text(theme.rawValue)
                                    .font(.system(size: 10, weight: isSel ? .bold : .medium))
                                    .foregroundStyle(MangaTheme.ink)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }

            // Typeface
            VStack(alignment: .leading, spacing: 10) {
                Text("Font Family")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)

                HStack(spacing: 8) {
                    ForEach(NovelTypeface.allCases) { item in
                        let isSel = typeface == item
                        Button {
                            typeface = item
                        } label: {
                            Text(item.rawValue)
                                .font(.system(size: 13, weight: isSel ? .bold : .medium, design: item.fontDesign))
                                .foregroundStyle(isSel ? .white : MangaTheme.ink)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isSel ? MangaTheme.vermilion : MangaTheme.surfaceContainer)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // Font Size Stepper
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Font Size")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(MangaTheme.ink)
                    Spacer()
                    Text("\(Int(fontSize))pt")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(MangaTheme.vermilion)
                }
                Slider(value: $fontSize, in: 14...26, step: 1)
                    .tint(MangaTheme.vermilion)
            }

            // Audio Drama Companion Tile
            HStack(spacing: 12) {
                Image(systemName: "headphones")
                    .font(.system(size: 20))
                    .foregroundStyle(MangaTheme.vermilion)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Whispersync Audio Companion")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(MangaTheme.ink)
                    Text("Listen in real-time synced with text reading.")
                        .font(.system(size: 11))
                        .foregroundStyle(MangaTheme.secondary)
                }
                Spacer()
                Toggle("", isOn: $audioDramaSync)
                    .labelsHidden()
                    .tint(MangaTheme.vermilion)
            }
            .padding(12)
            .background(MangaTheme.surfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()
        }
        .padding(20)
        .background(MangaTheme.surfaceLow)
    }
}

