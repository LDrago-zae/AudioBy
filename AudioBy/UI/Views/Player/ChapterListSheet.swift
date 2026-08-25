import SwiftUI

public struct ChapterListSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let chapters: [Chapter]
    public let currentChapterIndex: Int
    public let onSelectChapter: (Int) -> Void

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(chapters.enumerated()), id: \.element.id) { index, chapter in
                            Button {
                                onSelectChapter(index)
                                dismiss()
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(currentChapterIndex == index ? Theme.brandGreen : Color(white: 0.92))
                                            .frame(width: 36, height: 36)

                                        if currentChapterIndex == index {
                                            Image(systemName: "speaker.wave.2.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.white)
                                        } else {
                                            Text("\(chapter.chapterNumber)")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(Theme.textDark)
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(chapter.title)
                                            .font(.system(size: 15, weight: currentChapterIndex == index ? .bold : .medium))
                                            .foregroundColor(currentChapterIndex == index ? Theme.brandGreen : Theme.textDark)
                                            .lineLimit(1)

                                        Text("Duration: \(chapter.formattedDuration)")
                                            .font(.system(size: 12))
                                            .foregroundColor(Theme.textMuted)
                                    }

                                    Spacer()

                                    if currentChapterIndex == index {
                                        Text("Playing")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(Theme.brandGreen)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Theme.brandGreen.opacity(0.15))
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(currentChapterIndex == index ? Theme.brandGreen.opacity(0.08) : Color.white)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(currentChapterIndex == index ? Theme.brandGreen.opacity(0.2) : Color(white: 0.92), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Chapters & Tracks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.brandGreen)
                    .fontWeight(.bold)
                }
            }
        }
    }
}
