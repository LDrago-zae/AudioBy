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

    public init(book: Audiobook, chapter: Chapter) {
        self.book = book
        self.chapter = chapter
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()

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
                                Text(book.title)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Theme.brandCyan)
                                    .textCase(.uppercase)
                                    .tracking(1.0)

                                Text(chapter.title)
                                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                                    .foregroundColor(Theme.textDark)

                                Text("By \(book.author)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Theme.textMuted)
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
                            Text(currentChapterText.isEmpty ? chapter.fullText : currentChapterText)
                                .font(.system(size: fontSize, weight: .regular))
                                .lineSpacing(8)
                                .foregroundColor(Theme.textDark)
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
                            Text("Powered by Apple AVSpeechSynthesizer")
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
        }
    }

    private var selectedVoiceName: String {
        ttsService.availableVoices.first { $0.id == ttsService.selectedVoiceId }?.name ?? "Voice Narrator"
    }
}
