import SwiftUI
import Vision
import AVFoundation

public enum MangaReadingMode: String, CaseIterable, Identifiable {
    case rtl = "Manga (RTL)"
    case webtoon = "Strip (Scroll)"
    case doublePage = "Double Page"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .rtl: return "book.closed.fill"
        case .webtoon: return "rectangle.portrait.and.arrow.forward"
        case .doublePage: return "book.pages.fill"
        }
    }
}

public enum ReaderCanvasTheme: String, CaseIterable, Identifiable {
    case charcoal = "Dark Charcoal"
    case oled = "Black OLED"
    case ivory = "Warm Paper"
    case inverted = "Inverted"

    public var id: String { rawValue }

    public var backgroundColor: Color {
        switch self {
        case .charcoal: return MangaTheme.readerDark
        case .oled: return Color.black
        case .ivory: return MangaTheme.surface
        case .inverted: return Color(hex: "#E5E2D9")
        }
    }

    public var textColor: Color {
        switch self {
        case .charcoal, .oled: return MangaTheme.readerIvory
        case .ivory, .inverted: return MangaTheme.ink
        }
    }
}

public struct MangaReaderView: View {
    @Environment(\.dismiss) private var dismiss
    public let series: MangaSeries
    public let chapters: [MangaChapter]

    @State private var chapterIndex: Int
    @State private var pages: [URL] = []
    @State private var page: Int = 0
    @State private var readingMode: MangaReadingMode = .rtl
    @State private var canvasTheme: ReaderCanvasTheme = .charcoal
    @State private var zoom: CGFloat = 1
    @State private var loading = false
    @State private var message: String?
    @State private var player: AVAudioPlayer?
    @State private var isReadingAloud = false
    @State private var showHUD: Bool = true
    @State private var showSettingsDrawer: Bool = false
    @State private var luminance: Double = 0.85
    @State private var cropBorders: Bool = false
    @State private var showPageNumberOverlay: Bool = true

    @Bindable private var library = MangaLibrary.shared

    public init(series: MangaSeries, chapters: [MangaChapter], startChapterId: String) {
        self.series = series
        self.chapters = chapters
        let saved = MangaLibrary.shared.progress[series.id]
        let index = chapters.firstIndex { $0.id == startChapterId } ?? 0
        _chapterIndex = State(initialValue: index)
        _readingMode = State(initialValue: (saved?.vertical ?? false) ? .webtoon : .rtl)
        if saved?.chapterId == startChapterId {
            _page = State(initialValue: saved?.page ?? 0)
        }
    }

    private var currentChapter: MangaChapter? {
        chapters.indices.contains(chapterIndex) ? chapters[chapterIndex] : nil
    }

    public var body: some View {
        ZStack {
            canvasTheme.backgroundColor.ignoresSafeArea()

            // Immersive Manga Canvas
            mangaCanvas
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        showHUD.toggle()
                    }
                }

            // Top HUD Overlay
            if showHUD {
                VStack(spacing: 0) {
                    topHUD
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Bottom HUD Deck
            if showHUD {
                VStack(spacing: 0) {
                    Spacer()
                    bottomHUD
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showSettingsDrawer) {
            settingsDrawer
                .presentationDetents([.fraction(0.55), .medium])
                .presentationDragIndicator(.visible)
        }
        .task(id: chapterIndex) {
            await loadChapter()
        }
        .onChange(of: page) { _, _ in
            zoom = 1
            save()
        }
        .onDisappear {
            player?.stop()
            isReadingAloud = false
        }
    }

    // MARK: - Canvas Presentation
    private var mangaCanvas: some View {
        Group {
            if loading {
                VStack(spacing: 12) {
                    ProgressView().tint(MangaTheme.vermilion)
                    Text("Loading pages...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(canvasTheme.textColor.opacity(0.8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if pages.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 36))
                        .foregroundStyle(MangaTheme.vermilion)
                    Text(message ?? "No pages in this chapter.")
                        .font(.system(size: 14))
                        .foregroundStyle(canvasTheme.textColor)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                switch readingMode {
                case .rtl:
                    singlePageView(isRTL: true)
                case .webtoon:
                    webtoonScrollView
                case .doublePage:
                    doublePageSpreadView
                }
            }
        }
    }

    // MARK: - Single Page View (RTL)
    private func singlePageView(isRTL: Bool) -> some View {
        ZStack(alignment: .topTrailing) {
            if pages.indices.contains(page) {
                pageImage(pages[page])
                    .id(page)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay {
                        HStack(spacing: 0) {
                            // Left tap zone
                            Color.clear.contentShape(Rectangle())
                                .onTapGesture {
                                    stepPage(-1)
                                }
                            // Center zone toggles HUD
                            Color.clear.contentShape(Rectangle())
                                .frame(width: 120)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                        showHUD.toggle()
                                    }
                                }
                            // Right tap zone
                            Color.clear.contentShape(Rectangle())
                                .onTapGesture {
                                    stepPage(1)
                                }
                        }
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: page)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 30).onEnded { v in
                            guard zoom <= 1.05, abs(v.translation.width) > abs(v.translation.height) else { return }
                            // swipe right = next page, swipe left = previous page
                            stepPage(v.translation.width > 0 ? 1 : -1)
                        }
                    )
            }

            // Page Number Indicator Overlay (top right)
            if showPageNumberOverlay && !pages.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(MangaTheme.vermilion)
                    Text("PAGE \(page + 1)")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(MangaTheme.readerCard.opacity(0.85), in: Capsule())
                .padding(.top, 60)
                .padding(.trailing, 16)
            }
        }
    }

    // MARK: - Webtoon Scroll View
    private var webtoonScrollView: some View {
        GeometryReader { geo in
            ScrollView {
                LazyVStack(spacing: cropBorders ? 0 : 4) {
                    ForEach(pages.indices, id: \.self) { index in
                        pageImage(pages[index])
                            .frame(maxWidth: 780)
                            .frame(maxWidth: .infinity)
                            .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: Binding<Int?>(get: { page }, set: { if let val = $0 { page = val } }))
            .simultaneousGesture(
                SpatialTapGesture().onEnded { value in
                    let w = max(1, geo.size.width)
                    if value.location.x < w * 0.3 {
                        withAnimation { stepPage(-1) }
                    } else if value.location.x > w * 0.7 {
                        withAnimation { stepPage(1) }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { showHUD.toggle() }
                    }
                }
            )
        }
    }

    // MARK: - Double Page Spread
    private var doublePageSpreadView: some View {
        HStack(spacing: cropBorders ? 0 : 6) {
            let leftIndex = page + 1 < pages.count ? page + 1 : page
            let rightIndex = page

            if pages.indices.contains(leftIndex) {
                pageImage(pages[leftIndex])
                    .frame(maxWidth: .infinity)
            }
            if pages.indices.contains(rightIndex) && leftIndex != rightIndex {
                pageImage(pages[rightIndex])
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            HStack(spacing: 0) {
                Color.clear.contentShape(Rectangle()).onTapGesture { stepPage(-2) }
                Color.clear.contentShape(Rectangle()).frame(width: 140)
                    .onTapGesture {
                        withAnimation { showHUD.toggle() }
                    }
                Color.clear.contentShape(Rectangle()).onTapGesture { stepPage(2) }
            }
        }
    }

    private func pageImage(_ url: URL) -> some View {
        Group {
            if url.isFileURL, let uiImage = UIImage(contentsOfFile: url.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(zoom)
                    .gesture(MagnificationGesture().onChanged { zoom = min(4, max(1, $0)) })
            } else {
                CachedAsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(zoom)
                            .gesture(MagnificationGesture().onChanged { zoom = min(4, max(1, $0)) })
                    case .failure:
                        VStack(spacing: 8) {
                            Image(systemName: "wifi.exclamationmark")
                                .font(.system(size: 28))
                                .foregroundStyle(MangaTheme.vermilion)
                            Text("Couldn't load this page.")
                                .font(.system(size: 12))
                                .foregroundStyle(canvasTheme.textColor)
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                    case .empty:
                        ProgressView().tint(MangaTheme.vermilion)
                            .frame(maxWidth: .infinity, minHeight: 300)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
    }

    // MARK: - Top HUD Overlay
    private var topHUD: some View {
        VStack(spacing: 6) {
            // Sub-status bar
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(MangaTheme.vermilion)
                        .frame(width: 5, height: 5)
                    Text("Preloaded \(pages.count)/\(pages.count) pages")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                Spacer()
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: pages.allSatisfy(\.isFileURL) ? "arrow.down.circle.fill" : "wifi")
                            .font(.system(size: 10))
                        Text(pages.allSatisfy(\.isFileURL) ? "Offline" : "Online")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(Color.white.opacity(0.7))

                    HStack(spacing: 4) {
                        Image(systemName: "battery.100")
                            .font(.system(size: 10))
                        Text("84%")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(Color.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)

            // Main navigation row
            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.12), in: Circle())
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(series.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text(currentChapter?.title ?? "Chapter \(chapterIndex + 1)")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.8))
                            .lineLimit(1)
                        if readingMode == .rtl {
                            Text("RTL ACTIVE")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(0.5)
                                .foregroundStyle(MangaTheme.vermilion)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(MangaTheme.vermilion.opacity(0.2), in: Capsule())
                        }
                    }
                }

                Spacer()

                HStack(spacing: 6) {
                    // Speech OCR / Read Aloud Toggle
                    Button {
                        toggleReadAloud()
                    } label: {
                        Image(systemName: isReadingAloud ? "waveform" : "speaker.wave.2")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(isReadingAloud ? MangaTheme.vermilion : .white)
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.12), in: Circle())
                    }

                    // Brightness fast toggle
                    Button {
                        luminance = luminance > 0.5 ? 0.3 : 0.85
                    } label: {
                        Image(systemName: luminance > 0.5 ? "sun.max.fill" : "sun.min")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.12), in: Circle())
                    }

                    // Quick Settings Drawer Trigger
                    Button {
                        showSettingsDrawer = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.12), in: Circle())
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 50)
        .padding(.bottom, 12)
        .background(
            MangaTheme.readerCard.opacity(0.92)
                .ignoresSafeArea(edges: .top)
        )
        .overlay(
            Divider().background(Color.white.opacity(0.1)),
            alignment: .bottom
        )
    }

    // MARK: - Bottom HUD Deck
    private var bottomHUD: some View {
        VStack(spacing: 12) {
            // Chapter Nav & Live Page Status Pill
            HStack(spacing: 12) {
                Button {
                    stepChapter(-1)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "backward.end.fill")
                            .font(.system(size: 10))
                        Text(chapterIndex > 0 ? "Ch. \(chapterIndex)" : "First")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.12), in: Capsule())
                }
                .disabled(chapterIndex <= 0)

                Spacer()

                // Live Page Status Pill
                HStack(spacing: 4) {
                    Text("Page")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.7))
                    Text("\(page + 1)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(MangaTheme.vermilion)
                    Text("/ \(max(1, pages.count))")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.8))
                    if pages.count > 0 {
                        let pct = Int((Double(page + 1) / Double(pages.count)) * 100)
                        Text("(\(pct)%)")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.black.opacity(0.5), in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))

                Spacer()

                Button {
                    stepChapter(1)
                } label: {
                    HStack(spacing: 4) {
                        Text(chapterIndex < chapters.count - 1 ? "Ch. \(chapterIndex + 2)" : "Latest")
                            .font(.system(size: 12, weight: .bold))
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.12), in: Capsule())
                }
                .disabled(chapterIndex >= chapters.count - 1)
            }
            .padding(.horizontal, 16)

            // Precision Scrubber Track
            if !pages.isEmpty {
                VStack(spacing: 4) {
                    Slider(
                        value: Binding<Double>(
                            get: { Double(page) },
                            set: { page = Int($0) }
                        ),
                        in: 0...Double(max(0, pages.count - 1)),
                        step: 1
                    )
                    .tint(MangaTheme.vermilion)

                    HStack {
                        Text("1")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.6))
                        Spacer()
                        Text("\(pages.count)")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 20)
            }

            // Quick Reading Mode Selector
            HStack(spacing: 8) {
                ForEach(MangaReadingMode.allCases) { mode in
                    let isSel = readingMode == mode
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            readingMode = mode
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 12))
                            Text(mode.rawValue)
                                .font(.system(size: 12, weight: isSel ? .bold : .medium))
                        }
                        .foregroundStyle(isSel ? .white : Color.white.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            isSel ? MangaTheme.vermilion : Color.white.opacity(0.08),
                            in: Capsule()
                        )
                    }
                }
            }
            .padding(.horizontal, 16)

            // Drawer Peek Trigger
            Button {
                showSettingsDrawer = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "cpu")
                        .font(.system(size: 11))
                        .foregroundStyle(MangaTheme.vermilion)
                    Text("Komorebi Ink Engine 3.2")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.7))
                    Spacer()
                    Text("Reader Settings")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(MangaTheme.vermilion)
                    Image(systemName: "chevron.up")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(MangaTheme.vermilion)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }
        }
        .padding(.top, 14)
        .padding(.bottom, 28)
        .background(
            MangaTheme.readerCard.opacity(0.94)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))
                .shadow(color: Color.black.opacity(0.35), radius: 20, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Quick Settings Drawer
    private var settingsDrawer: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reader Customization")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(MangaTheme.ink)
                    Text("Engine: Komorebi Ink 3.2")
                        .font(.system(size: 12))
                        .foregroundStyle(MangaTheme.secondary)
                }
                Spacer()
                Button {
                    showSettingsDrawer = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(MangaTheme.secondary)
                }
            }

            Divider().background(MangaTheme.hairline)

            // Canvas Theme Selector
            VStack(alignment: .leading, spacing: 10) {
                Text("Canvas & Background Theme")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)

                HStack(spacing: 8) {
                    ForEach(ReaderCanvasTheme.allCases) { theme in
                        let isSel = canvasTheme == theme
                        Button {
                            canvasTheme = theme
                        } label: {
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(theme.backgroundColor)
                                    .frame(width: 32, height: 32)
                                    .overlay(Circle().stroke(isSel ? MangaTheme.vermilion : MangaTheme.hairline, lineWidth: 2))
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

            // Luminance Slider
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Luminance / Brightness")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(MangaTheme.ink)
                    Spacer()
                    Text("\(Int(luminance * 100))%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(MangaTheme.vermilion)
                }
                Slider(value: $luminance, in: 0.1...1.0)
                    .tint(MangaTheme.vermilion)
            }

            // Toggles
            VStack(spacing: 12) {
                Toggle("Crop Margin Hairlines", isOn: $cropBorders)
                    .tint(MangaTheme.vermilion)
                Toggle("Show Page Number Overlay", isOn: $showPageNumberOverlay)
                    .tint(MangaTheme.vermilion)
            }

            Spacer()
        }
        .padding(20)
        .background(MangaTheme.surfaceLow)
    }

    // MARK: - Actions
    private func stepPage(_ delta: Int) {
        let next = page + delta
        guard pages.indices.contains(next) else { return }
        page = next
    }

    private func stepChapter(_ delta: Int) {
        let next = chapterIndex + delta
        guard chapters.indices.contains(next) else { return }
        chapterIndex = next
        page = 0
    }

    private func loadChapter() async {
        guard chapters.indices.contains(chapterIndex) else { return }
        loading = true
        message = nil
        defer { loading = false }
        let chapter = chapters[chapterIndex]
        pages = await MangaCatalogService.shared.pageURLs(series: series, chapter: chapter)
        if pages.isEmpty {
            message = "No readable pages for this chapter. MangaDex only hosts some English scans — try another chapter or series."
        }
        if page >= pages.count { page = 0 }
        save()
    }

    private func save() {
        guard chapters.indices.contains(chapterIndex) else { return }
        MangaLibrary.shared.remember(
            seriesId: series.id,
            chapterId: chapters[chapterIndex].id,
            page: page,
            vertical: readingMode == .webtoon
        )
    }

    private func toggleReadAloud() {
        if isReadingAloud {
            player?.pause()
            isReadingAloud = false
            return
        }
        if let player, player.currentTime > 0, !player.isPlaying {
            player.play()
            isReadingAloud = true
            return
        }
        Task { await readAloud() }
    }

    private func readAloud() async {
        guard pages.indices.contains(page) else { return }
        message = nil
        do {
            let (data, _) = try await URLSession.shared.data(from: pages[page])
            guard let image = UIImage(data: data), let cgImage = image.cgImage else {
                message = "Nothing to read on this page."
                return
            }
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])
            let lines = (request.results ?? [])
                .sorted { $0.boundingBox.midY > $1.boundingBox.midY }
                .compactMap { $0.topCandidates(1).first?.string }
            let text = lines.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else {
                message = "Nothing to read on this page."
                return
            }
            let voice = TTSEngineService.shared.selectedLanguageCode
            let url = try await EdgeSpeechService.shared.synthesize(
                text: text,
                voice: voice,
                cacheKey: "manga-\(chapters[chapterIndex].id)-\(page)-\(voice)"
            )
            let audio = try AVAudioPlayer(contentsOf: url)
            player = audio
            audio.play()
            isReadingAloud = true
            message = nil
        } catch {
            message = error.localizedDescription
        }
    }
}
