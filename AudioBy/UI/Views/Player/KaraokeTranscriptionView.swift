import SwiftUI

public struct KaraokeTranscriptionView: View {
    public let chapter: Chapter?
    public let currentTime: TimeInterval
    public let playbackDuration: TimeInterval
    public let onSeek: (TimeInterval) -> Void
    public var onRetry: (() -> Void)? = nil
    public var isLoading: Bool = false

    public init(
        chapter: Chapter?,
        currentTime: TimeInterval,
        playbackDuration: TimeInterval = 0,
        isLoading: Bool = false,
        onSeek: @escaping (TimeInterval) -> Void,
        onRetry: (() -> Void)? = nil
    ) {
        self.chapter = chapter
        self.currentTime = currentTime
        self.playbackDuration = playbackDuration
        self.isLoading = isLoading
        self.onSeek = onSeek
        self.onRetry = onRetry
    }

    private var segments: [TranscriptSegment] {
        guard let chap = chapter else { return [] }
        let duration = max(playbackDuration > 1 ? playbackDuration : chap.duration, 30)
        if chap.hasReadableText {
            return TranscriptSegment.generateSegments(from: chap.fullText, chapterDuration: duration)
        }
        if !chap.transcriptSegments.isEmpty {
            return chap.transcriptSegments
        }
        return []
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Header label
                    HStack {
                        Image(systemName: "waveform.and.magnifyingglass")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Theme.brandGreen)
                        Text("LIVE SYNCHRONIZED TRANSCRIPTION")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.brandGreen)
                            .tracking(1.2)
                        Spacer()
                    }
                    .padding(.top, 8)

                    if isLoading {
                        VStack(spacing: 12) {
                            ProgressView().tint(Theme.brandGreen)
                            Text("Fetching synchronized chapter text...")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Theme.textMuted)
                        }
                        .padding(.vertical, 40)
                        .frame(maxWidth: .infinity)
                    } else if segments.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "text.quote")
                                .font(.system(size: 28))
                                .foregroundColor(Theme.brandGreen)
                            Text("No Transcription Available")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            Text("Readable text for this chapter has not loaded yet. Retry to fetch it from Project Gutenberg.")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textMuted)
                                .multilineTextAlignment(.center)
                            if let onRetry {
                                Button(action: onRetry) {
                                    Text("Retry transcription")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Theme.brandGreen)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.vertical, 40)
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(segments) { segment in
                            let isCurrent = segment.isActive(at: currentTime)

                            Button {
                                onSeek(segment.startTime)
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    // Word by word flow
                                    FlowLayout(spacing: 6) {
                                        ForEach(segment.words) { word in
                                            let isWordActive = word.isActive(at: currentTime)
                                            let isWordPast = word.isPassed(at: currentTime)

                                            Text(word.word)
                                                .font(.system(size: isCurrent ? 24 : 20, weight: isWordActive ? .black : (isCurrent ? .bold : .medium), design: .rounded))
                                                .foregroundColor(
                                                    isWordActive
                                                        ? Theme.brandGreenLight
                                                        : (isWordPast || isCurrent
                                                            ? Color.white
                                                            : Color.white.opacity(0.35))
                                                )
                                                .shadow(color: isWordActive ? Theme.brandGreen.opacity(0.6) : Color.clear, radius: 8, x: 0, y: 0)
                                                .animation(.easeInOut(duration: 0.18), value: isWordActive)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(isCurrent ? Color.white.opacity(0.08) : Color.clear)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                    .stroke(isCurrent ? Theme.brandGreen.opacity(0.3) : Color.clear, lineWidth: 1)
                                            )
                                    )
                                }
                                .id(segment.id)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 16)
            }
            .onChange(of: currentActiveSegmentId) { _, newId in
                if let id = newId {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private var currentActiveSegmentId: String? {
        segments.first { $0.isActive(at: currentTime) }?.id
    }
}

// MARK: - FlowLayout Helper for Word Wrapping
private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 300
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentRowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width && currentX > 0 {
                height += currentRowHeight + spacing
                currentX = 0
                currentRowHeight = 0
            }
            currentX += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }
        height += currentRowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var currentRowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentY += currentRowHeight + spacing
                currentX = bounds.minX
                currentRowHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }
    }
}
