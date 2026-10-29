import SwiftUI
import Vision
import AVFoundation

public struct MangaReaderView: View {
    @Environment(\.dismiss) private var dismiss
    public let series: MangaSeries
    public let chapters: [MangaChapter]
    @State private var chapterIndex: Int
    @State private var pages: [URL] = []
    @State private var page: Int = 0
    @State private var vertical: Bool
    @State private var zoom: CGFloat = 1
    @State private var loading = false
    @State private var message: String?
    @State private var player: AVAudioPlayer?
    @State private var isReadingAloud = false

    public init(series: MangaSeries, chapters: [MangaChapter], startChapterId: String) {
        self.series = series
        self.chapters = chapters
        let saved = MangaLibrary.shared.progress[series.id]
        let index = chapters.firstIndex { $0.id == startChapterId } ?? 0
        _chapterIndex = State(initialValue: index)
        _vertical = State(initialValue: saved?.vertical ?? false)
        if saved?.chapterId == startChapterId {
            _page = State(initialValue: saved?.page ?? 0)
        }
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if loading {
                ProgressView().tint(.white)
            } else if pages.isEmpty {
                Text(message ?? "No pages in this chapter.")
                    .foregroundStyle(.white)
                    .padding()
            } else if vertical {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(pages.indices, id: \.self) { index in
                            pageImage(pages[index])
                                .id(index)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollPosition(id: Binding<Int?>(get: { page }, set: { if let value = $0 { page = value } }))
            } else {
                pageImage(pages[min(page, pages.count - 1)])
                    .id(page)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay {
                        HStack(spacing: 0) {
                            Color.clear.contentShape(Rectangle()).onTapGesture { stepPage(-1) }
                            Color.clear.contentShape(Rectangle()).frame(width: 80)
                            Color.clear.contentShape(Rectangle()).onTapGesture { stepPage(1) }
                        }
                    }
                    .animation(.spring(response: 0.38, dampingFraction: 0.86), value: page)
            }
        }
        .safeAreaInset(edge: .top) { topBar }
        .safeAreaInset(edge: .bottom) { bottomBar }
        .navigationBarHidden(true)
        .task(id: chapterIndex) { await loadChapter() }
        .onChange(of: page) { _, _ in
            zoom = 1
            save()
        }
        .onDisappear {
            player?.stop()
            isReadingAloud = false
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel("Close")
            Text(chapters.indices.contains(chapterIndex) ? chapters[chapterIndex].title : series.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
            Spacer()
            Text(pages.isEmpty ? "" : "\(page + 1) / \(pages.count)")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.92))
    }

    private var bottomBar: some View {
        VStack(spacing: 8) {
            if let message {
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            if !pages.isEmpty {
                GeometryReader { geo in
                    let fraction = pages.count <= 1 ? 1 : CGFloat(page + 1) / CGFloat(pages.count)
                    Capsule()
                        .fill(Color.white.opacity(0.25))
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(Theme.brandGreen)
                                .frame(width: max(8, geo.size.width * fraction))
                        }
                }
                .frame(height: 4)
            }
            HStack(spacing: 8) {
                barButton(vertical ? "Pages" : "Strip") { vertical.toggle(); save() }
                barButton(isReadingAloud ? "Pause" : "Read") { toggleReadAloud() }
                barButton("Next") { stepChapter(1) }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.92))
    }

    private func barButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.black)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Theme.brandGreen)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func pageImage(_ url: URL) -> some View {
        AsyncImage(url: url) { image in
            image.resizable().scaledToFit()
                .scaleEffect(zoom)
                .gesture(MagnificationGesture().onChanged { zoom = min(4, max(1, $0)) })
        } placeholder: {
            ProgressView().tint(.white).frame(maxWidth: .infinity, minHeight: 240)
        }
        .frame(maxWidth: .infinity)
    }

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
        if !chapter.imagePaths.isEmpty {
            pages = chapter.imagePaths.map { URL(fileURLWithPath: $0) }
        } else {
            do {
                pages = try await MangaDexService.shared.pageURLs(chapterId: chapter.id)
            } catch {
                pages = []
                message = error.localizedDescription
            }
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
            vertical: vertical
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
