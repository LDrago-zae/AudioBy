import Foundation

/// Represents a word-level timestamp in a chapter transcript.
public struct TranscriptWord: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let word: String
    public let startTime: TimeInterval
    public let endTime: TimeInterval

    public init(
        id: String = UUID().uuidString,
        word: String,
        startTime: TimeInterval,
        endTime: TimeInterval
    ) {
        self.id = id
        self.word = word
        self.startTime = startTime
        self.endTime = endTime
    }

    public func isActive(at time: TimeInterval) -> Bool {
        time >= startTime && time < endTime
    }

    public func isPassed(at time: TimeInterval) -> Bool {
        time >= endTime
    }
}

/// Represents a timestamped sentence or paragraph segment in a chapter transcript.
public struct TranscriptSegment: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let text: String
    public let startTime: TimeInterval
    public let endTime: TimeInterval
    public let words: [TranscriptWord]

    public init(
        id: String = UUID().uuidString,
        text: String,
        startTime: TimeInterval,
        endTime: TimeInterval,
        words: [TranscriptWord] = []
    ) {
        self.id = id
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
        self.words = words.isEmpty ? Self.generateWords(from: text, start: startTime, end: endTime) : words
    }

    public func isActive(at time: TimeInterval) -> Bool {
        time >= startTime && time < endTime
    }

    public func isPassed(at time: TimeInterval) -> Bool {
        time >= endTime
    }

    /// Automatically breaks a sentence down into estimated word-level timestamps.
    public static func generateWords(from text: String, start: TimeInterval, end: TimeInterval) -> [TranscriptWord] {
        let tokens = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return [] }

        let duration = max(end - start, 0.5)
        let slice = duration / Double(tokens.count)

        return tokens.enumerated().map { index, token in
            let wStart = start + (Double(index) * slice)
            let wEnd = wStart + slice
            return TranscriptWord(
                id: UUID().uuidString,
                word: token,
                startTime: wStart,
                endTime: wEnd
            )
        }
    }

    /// Generates live synchronized transcript segments from any chapter fullText.
    public static func generateSegments(from text: String, chapterDuration: TimeInterval) -> [TranscriptSegment] {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return [] }

        // Split text into natural sentences
        var sentences: [String] = []
        cleanText.enumerateSubstrings(in: cleanText.startIndex..<cleanText.endIndex, options: .bySentences) { substring, _, _, _ in
            if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
                sentences.append(s)
            }
        }

        if sentences.isEmpty {
            sentences = cleanText.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }
        guard !sentences.isEmpty else { return [] }

        let totalWordCount = max(1, sentences.reduce(0) { $0 + $1.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count })
        let effectiveDuration = max(chapterDuration, Double(totalWordCount) / 150.0 * 60.0)

        var accumulatedTime: TimeInterval = 0
        var segments: [TranscriptSegment] = []

        for (index, sentence) in sentences.enumerated() {
            let sentenceWords = sentence.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
            let wordFraction = Double(sentenceWords.count) / Double(totalWordCount)
            let sentenceDuration = max(2.5, wordFraction * effectiveDuration)

            let segStart = accumulatedTime
            let segEnd = segStart + sentenceDuration
            accumulatedTime = segEnd

            segments.append(
                TranscriptSegment(
                    id: "ts-seg-\(index)",
                    text: sentence,
                    startTime: segStart,
                    endTime: segEnd
                )
            )
        }

        return segments
    }
}
