import SwiftUI

public struct BookReaderView: View {
    public let book: Audiobook
    public let chapter: Chapter
    @Environment(\.dismiss) private var dismiss
    @Bindable var ttsService = TTSEngineService.shared
    @State private var fontSize: CGFloat = 18
    @State private var showingVoicePicker = false
    @State private var currentChapterText: String = ""
    @State private var isLoadingRealText = false
    @State private var showingScenes = false
    @State private var showingPaywall = false
    @Bindable var scenes = ReaderSceneStore.shared

    public init(book: Audiobook, chapter: Chapter) {
        self.book = book
        self.chapter = chapter
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                SceneBackdrop(scene: scenes.active, scrim: 0.55)

                VStack(spacing: 0) {
                    // Top Bar with Voice Selector & Font Size
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Theme.textDark)
                                .frame(width: 40, height: 40)
                                .background(Theme.surfaceWhite)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Theme.cardBorder, lineWidth: 1))
                        }

                        Spacer()

                        // Voice Picker Trigger
                        Button {
                            showingVoicePicker = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "waveform.and.person.filled")
                                    .font(.system(size: 13))
                                Text(selectedVoiceName)
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundColor(Theme.brandGreen)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Theme.brandGreen.opacity(0.12))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Theme.brandGreen.opacity(0.3), lineWidth: 1))
                        }

                        // Font size control
                        Button {
                            showingScenes = true
                        } label: {
                            Image(systemName: "photo")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.black.opacity(0.35))
                                .clipShape(Circle())
                        }

                        Button {
                            withAnimation {
                                fontSize = fontSize >= 22 ? 16 : fontSize + 2
                            }
                        } label: {
                            Image(systemName: "textformat.size")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Theme.textDark)
                                .frame(width: 40, height: 40)
                                .background(Theme.surfaceWhite)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Theme.cardBorder, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)

                    // Scrollable Chapter Text with Live TTS Synchronization
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            // Header
                            VStack(alignment: .leading, spacing: 6) {
                                Text(chapter.title)
                                    .font(.system(size: 24, weight: .bold, design: .serif))
                                    .foregroundColor(.white)

                                Text("By \(book.author)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.75))
                            }
                            .padding(.top, 10)

                            Divider().background(Theme.cardBorder)

                            if isLoadingRealText {
                                HStack(spacing: 10) {
                                    ProgressView()
                                        .tint(Theme.brandGreen)
                                    Text("Fetching original text...")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Theme.brandGreen)
                                }
                                .padding(.vertical, 20)
                            } else if currentChapterText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                VStack(spacing: 10) {
                                    Text("No readable text is available for this chapter.")
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.textMuted)
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
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Theme.brandGreen)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.vertical, 20)
                            }

                            // Highlighted Body Text
                            VStack(alignment: .leading, spacing: 18) {
                                ForEach(Array(readingParagraphs.enumerated()), id: \.offset) { _, paragraph in
                                    let spoken = spokenSentence(in: paragraph)
                                    Text(attributedParagraph(paragraph, spoken: spoken))
                                        .font(.system(size: fontSize, weight: .regular, design: .serif))
                                        .lineSpacing(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding(.bottom, 120)
                        }
                        .padding(.horizontal, 22)
                    }

                    // Floating Bottom Narration Control Bar
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ttsService.isPlaying ? "Speaking Live..." : "Native Voice Narration")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Theme.brandGreen)
                            Text("Neural voice")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textMuted)
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
                                    .font(.system(size: 14, weight: .bold))
                                Text(ttsService.isPlaying ? "Pause" : "Listen")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Theme.brandGreen)
                            .clipShape(Capsule())
                            .shadow(color: Theme.brandGreen.opacity(0.35), radius: 6, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Theme.surfaceWhite)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Theme.cardBorder),
                        alignment: .top
                    )
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                if currentChapterText.isEmpty {
                    currentChapterText = chapter.fullText
                }
            }
            .task {
                if currentChapterText.isEmpty {
                    currentChapterText = chapter.fullText
                }
                let needsFetch = currentChapterText.trimmingCharacters(in: .whitespacesAndNewlines).count < 80
                if needsFetch {
                    isLoadingRealText = true
                    let liveChapters = await AudiobookRepository.shared.loadLiveChapters(for: book.id, forceRefresh: false)
                    if let matched = liveChapters.first(where: { $0.id == chapter.id || $0.chapterNumber == chapter.chapterNumber }),
                       matched.hasReadableText {
                        currentChapterText = matched.fullText
                    } else if let withText = liveChapters.first(where: { $0.hasReadableText }) {
                        currentChapterText = withText.fullText
                    }
                    isLoadingRealText = false
                }
            }
            .sheet(isPresented: $showingVoicePicker) {
                VoicePickerSheet()
            }
            .sheet(isPresented: $showingScenes) {
                ScenePickerSheet(showingPaywall: $showingPaywall)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    private func spokenSentence(in paragraph: String) -> String? {
        guard ttsService.isPlaying || ttsService.isPaused,
              let range = ttsService.currentWordRange,
              let swiftRange = Range(range, in: ttsService.currentText) else { return nil }
        let word = String(ttsService.currentText[swiftRange])
        guard paragraph.contains(word) else { return nil }
        let sentences = paragraph.components(separatedBy: ". ")
        return sentences.first { $0.contains(word) }
    }

    private func attributedParagraph(_ paragraph: String, spoken: String?) -> AttributedString {
        var text = AttributedString(paragraph)
        text.foregroundColor = .white
        if let spoken, let range = text.range(of: spoken) {
            text[range].backgroundColor = Theme.brandGreen
            text[range].foregroundColor = .black
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
