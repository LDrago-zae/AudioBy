import SwiftUI

// MARK: - Reader appearance

public enum ReaderPageTheme: String, CaseIterable, Identifiable {
    case original = "Original"
    case quiet = "Quiet"
    case paper = "Paper"
    case bold = "Bold"
    case calm = "Calm"
    case focus = "Focus"

    public var id: String { rawValue }

    var background: Color {
        switch self {
        case .original: return Color(hex: "#FFFFFF")
        case .quiet: return Color(hex: "#F1E3C8")
        case .paper: return Color(hex: "#FFFCF2")
        case .bold: return Color.black
        case .calm: return Color(hex: "#3B372F")
        case .focus: return Color(hex: "#1C1C1E")
        }
    }

    var text: Color {
        switch self {
        case .original, .paper: return Color(hex: "#1C1B19")
        case .quiet: return Color(hex: "#3A2E1C")
        case .bold: return Color.white
        case .calm: return Color(hex: "#E9E1D0")
        case .focus: return Color(hex: "#E5E5E7")
        }
    }

    var secondary: Color { text.opacity(0.55) }
    var isDark: Bool { self == .bold || self == .calm || self == .focus }

    var design: Font.Design {
        switch self {
        case .bold, .focus: return .default
        default: return .serif
        }
    }

    var weight: Font.Weight { self == .bold ? .semibold : .regular }
}

public struct BookReaderView: View {
    public let book: Audiobook
    public let chapter: Chapter
    @Environment(\.dismiss) private var dismiss
    @Bindable var ttsService = TTSEngineService.shared
    @Bindable var scenes = ReaderSceneStore.shared

    @AppStorage("reader.fontSize") private var fontSize: Double = 19
    @AppStorage("reader.theme") private var themeRaw: String = ReaderPageTheme.paper.rawValue
    @AppStorage("reader.brightness") private var brightness: Double = 1.0
    @AppStorage("reader.justify") private var justify: Bool = true

    @State private var showingVoicePicker = false
    @State private var showingScenes = false
    @State private var showingPaywall = false
    @State private var showingSettings = false
    @State private var showChrome = true
    @State private var currentChapterText: String = ""
    @State private var isLoadingRealText = false
    @State private var visibleIndex = 0

    public init(book: Audiobook, chapter: Chapter) {
        self.book = book
        self.chapter = chapter
    }

    private var theme: ReaderPageTheme { ReaderPageTheme(rawValue: themeRaw) ?? .paper }

    public var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                if showChrome { topBar.transition(.move(edge: .top).combined(with: .opacity)) }

                content

                footer
            }

            // Software dimming (works even in the simulator)
            Color.black
                .opacity(max(0, 1 - brightness) * 0.75)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            if showChrome { listenDock }
        }
        .preferredColorScheme(theme.isDark ? .dark : .light)
        .statusBarHidden(!showChrome)
        .sheet(isPresented: $showingSettings) {
            ReaderSettingsSheet(
                themeRaw: $themeRaw,
                fontSize: $fontSize,
                brightness: $brightness,
                justify: $justify
            )
            .presentationDetents([.height(430), .large])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled(upThrough: .height(430)))
        }
        .sheet(isPresented: $showingVoicePicker) { VoicePickerSheet() }
        .sheet(isPresented: $showingScenes) { ScenePickerSheet(showingPaywall: $showingPaywall) }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .task { await loadText() }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(spacing: 10) {
            chromeButton("chevron.left") { dismiss() }

            VStack(alignment: .leading, spacing: 1) {
                Text(book.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.text)
                    .lineLimit(1)
                Text(chapter.title)
                    .font(.system(size: 11))
                    .foregroundStyle(theme.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            chromeButton("waveform.and.person.filled") { showingVoicePicker = true }
            chromeButton("photo") { showingScenes = true }
            chromeButton("textformat.size") { showingSettings = true }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func chromeButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(theme.text)
                .frame(width: 36, height: 36)
                .background(theme.text.opacity(0.08), in: Circle())
        }
    }

    // MARK: Content

    private var content: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Chapter \(chapter.chapterNumber)")
                            .font(.system(size: fontSize + 1, weight: .regular, design: theme.design))
                            .foregroundStyle(theme.secondary)
                        Text(chapter.title)
                            .font(.system(size: fontSize + 8, weight: theme == .bold ? .bold : .regular, design: theme.design))
                            .foregroundStyle(theme.text)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("By \(book.author)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(theme.secondary)
                            .padding(.top, 2)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 22)

                    if isLoadingRealText {
                        HStack(spacing: 10) {
                            ProgressView().tint(MangaTheme.vermilion)
                            Text("Fetching original text…")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(theme.secondary)
                        }
                        .padding(.vertical, 24)
                    } else if readingParagraphs.isEmpty {
                        emptyState
                    }

                    ForEach(Array(readingParagraphs.enumerated()), id: \.offset) { index, paragraph in
                        let spoken = spokenSentence(in: paragraph)
                        Text(attributedParagraph(paragraph, spoken: spoken))
                            .font(.system(size: fontSize, weight: theme.weight, design: theme.design))
                            .lineSpacing(fontSize * 0.42)
                            .multilineTextAlignment(justify ? .leading : .leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, fontSize * 0.9)
                            .id(index)
                            .onAppear { visibleIndex = max(visibleIndex, index) }
                    }

                    Color.clear.frame(height: 160)
                }
                .padding(.horizontal, 24)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) { showChrome.toggle() }
            }
            .pageTapScroll()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No readable text is available for this chapter.")
                .font(.system(size: 14))
                .foregroundStyle(theme.secondary)
                .multilineTextAlignment(.center)
            Button {
                Task {
                    isLoadingRealText = true
                    let live = await AudiobookRepository.shared.retryChapters(for: book.id)
                    if let matched = live.first(where: { $0.id == chapter.id || $0.chapterNumber == chapter.chapterNumber }),
                       matched.hasReadableText {
                        currentChapterText = matched.fullText
                    } else if let withText = live.first(where: { $0.hasReadableText }) {
                        currentChapterText = withText.fullText
                    }
                    isLoadingRealText = false
                }
            } label: {
                Text("Retry text")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(MangaTheme.vermilion, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    // MARK: Footer & Listen dock

    private var footer: some View {
        let total = max(readingParagraphs.count, 1)
        let current = min(visibleIndex + 1, total)
        return Text(readingParagraphs.isEmpty ? " " : "\(current) of \(total)")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(theme.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(theme.background)
    }

    private var listenDock: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ttsService.isPlaying ? "Speaking live…" : "Listen to this chapter")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(theme.text)
                    Text(selectedVoiceName)
                        .font(.system(size: 11))
                        .foregroundStyle(theme.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Button {
                    let textToSpeak = currentChapterText.isEmpty ? chapter.fullText : currentChapterText
                    if ttsService.isPlaying {
                        ttsService.pause()
                    } else if ttsService.isPaused {
                        ttsService.resume()
                    } else {
                        ttsService.speak(text: textToSpeak, bookTitle: book.title, chapterTitle: chapter.title)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: ttsService.isPlaying ? "pause.fill" : "play.fill")
                        Text(ttsService.isPlaying ? "Pause" : "Listen")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(MangaTheme.vermilion, in: Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(theme.text.opacity(0.1), lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.bottom, 34)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: Data

    private func loadText() async {
        if currentChapterText.isEmpty { currentChapterText = chapter.fullText }
        let needsFetch = currentChapterText.trimmingCharacters(in: .whitespacesAndNewlines).count < 80
        guard needsFetch else { return }
        isLoadingRealText = true
        let live = await AudiobookRepository.shared.loadLiveChapters(for: book.id, forceRefresh: false)
        if let matched = live.first(where: { $0.id == chapter.id || $0.chapterNumber == chapter.chapterNumber }),
           matched.hasReadableText {
            currentChapterText = matched.fullText
        } else if let withText = live.first(where: { $0.hasReadableText }) {
            currentChapterText = withText.fullText
        }
        isLoadingRealText = false
    }

    private func spokenSentence(in paragraph: String) -> String? {
        guard ttsService.isPlaying || ttsService.isPaused,
              let range = ttsService.currentWordRange,
              let swiftRange = Range(range, in: ttsService.currentText) else { return nil }
        let word = String(ttsService.currentText[swiftRange])
        guard paragraph.contains(word) else { return nil }
        return paragraph.components(separatedBy: ". ").first { $0.contains(word) }
    }

    private func attributedParagraph(_ paragraph: String, spoken: String?) -> AttributedString {
        var text = AttributedString(paragraph)
        text.foregroundColor = theme.text
        if let spoken, let range = text.range(of: spoken) {
            text[range].backgroundColor = MangaTheme.vermilion.opacity(0.35)
        }
        return text
    }

    private var readingParagraphs: [String] {
        let raw = (currentChapterText.isEmpty ? chapter.fullText : currentChapterText)
            .replacingOccurrences(of: "\r\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return [] }
        let blocks = raw
            .components(separatedBy: "\n\n")
            .map { $0.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if blocks.count > 1 { return blocks }
        let sentences = raw.replacingOccurrences(of: "\n", with: " ")
            .components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if sentences.count < 4 { return [raw] }
        var groups: [String] = []
        var index = 0
        while index < sentences.count {
            let end = min(index + 3, sentences.count)
            let piece = sentences[index..<end].joined(separator: ". ")
            groups.append(piece.hasSuffix(".") ? piece : piece + ".")
            index = end
        }
        return groups
    }

    private var selectedVoiceName: String {
        ttsService.availableVoices.first { $0.id == ttsService.selectedVoiceId }?.name ?? "Voice Narrator"
    }
}

// MARK: - Settings bottom sheet

struct ReaderSettingsSheet: View {
    @Binding var themeRaw: String
    @Binding var fontSize: Double
    @Binding var brightness: Double
    @Binding var justify: Bool
    @Environment(\.dismiss) private var dismiss

    private var current: ReaderPageTheme { ReaderPageTheme(rawValue: themeRaw) ?? .paper }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(MangaTheme.secondary)
                        .frame(width: 30, height: 30)
                        .background(MangaTheme.surfaceContainer, in: Circle())
                }
                Spacer()
                Text("Reading Settings")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)
                Spacer()
                Color.clear.frame(width: 30, height: 30)
            }

            HStack(spacing: 12) {
                // Font size
                HStack(spacing: 0) {
                    stepper(label: "A", size: 14) { fontSize = max(14, fontSize - 1) }
                    Divider().frame(height: 22)
                    stepper(label: "A", size: 22) { fontSize = min(30, fontSize + 1) }
                }
                .background(MangaTheme.surfaceLow, in: Capsule())
                .overlay(Capsule().stroke(MangaTheme.hairline, lineWidth: 1))

                // Brightness
                HStack(spacing: 8) {
                    Image(systemName: "sun.min")
                        .font(.system(size: 13))
                        .foregroundStyle(MangaTheme.secondary)
                    Slider(value: $brightness, in: 0.3...1.0)
                        .tint(MangaTheme.vermilion)
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(MangaTheme.secondary)
                }
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(MangaTheme.surfaceLow, in: Capsule())
                .overlay(Capsule().stroke(MangaTheme.hairline, lineWidth: 1))
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(ReaderPageTheme.allCases) { t in
                    let selected = t == current
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { themeRaw = t.rawValue }
                    } label: {
                        VStack(spacing: 2) {
                            Text("Aa")
                                .font(.system(size: 22, weight: t == .bold ? .bold : .regular, design: t.design))
                                .foregroundStyle(t.text)
                            Text(t.rawValue)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(t.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 70)
                        .background(t.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(selected ? MangaTheme.vermilion : MangaTheme.hairline, lineWidth: selected ? 2.5 : 1)
                        )
                        .overlay(alignment: .bottomTrailing) {
                            if selected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(MangaTheme.vermilion)
                                    .padding(6)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            // Live preview
            Text("The world outside was changing rapidly, yet within the walls time seemed to stand still.")
                .font(.system(size: fontSize, weight: current.weight, design: current.design))
                .lineSpacing(fontSize * 0.35)
                .foregroundStyle(current.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(current.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(MangaTheme.hairline, lineWidth: 1))

            Spacer(minLength: 0)
        }
        .padding(20)
        .background(MangaTheme.surface.ignoresSafeArea())
    }

    private func stepper(label: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(MangaTheme.ink)
                .frame(width: 64, height: 44)
        }
    }
}
