import Foundation

/// Represents a chapter within an audiobook, supporting both remote streaming audio and native text-to-speech reading.
public struct Chapter: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let chapterNumber: Int
    public let startTime: TimeInterval
    public let duration: TimeInterval
    public let audioResourceName: String?
    public let remoteAudioURL: URL?
    public let transcriptSegments: [TranscriptSegment]
    public let fullText: String

    public init(
        id: String = UUID().uuidString,
        title: String,
        chapterNumber: Int,
        startTime: TimeInterval,
        duration: TimeInterval,
        audioResourceName: String? = nil,
        remoteAudioURL: URL? = nil,
        transcriptSegments: [TranscriptSegment] = [],
        fullText: String = ""
    ) {
        self.id = id
        self.title = title
        self.chapterNumber = chapterNumber
        self.startTime = startTime
        self.duration = duration
        self.audioResourceName = audioResourceName
        self.remoteAudioURL = remoteAudioURL
        self.transcriptSegments = transcriptSegments
        self.fullText = fullText.isEmpty ? Self.defaultTextFromSegments(transcriptSegments) : fullText
    }

    public var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
        return "\(minutes):\(String(format: "%02d", seconds))"
    }

    public var hasReadableText: Bool {
        fullText.trimmingCharacters(in: .whitespacesAndNewlines).count > 40
    }

    public func currentSegment(at time: TimeInterval) -> TranscriptSegment? {
        transcriptSegments.first { $0.isActive(at: time) }
    }

    /// Builds karaoke-style timed segments from `fullText` when they were not supplied by the API.
    public func ensuringTranscript(usingDuration overrideDuration: TimeInterval? = nil) -> Chapter {
        let playDuration = max(overrideDuration ?? duration, 30)
        if !hasReadableText {
            return self
        }
        let segments = TranscriptSegment.generateSegments(from: fullText, chapterDuration: playDuration)
        return Chapter(
            id: id,
            title: title,
            chapterNumber: chapterNumber,
            startTime: startTime,
            duration: duration,
            audioResourceName: audioResourceName,
            remoteAudioURL: remoteAudioURL,
            transcriptSegments: segments,
            fullText: fullText
        )
    }

    public func replacingText(_ text: String) -> Chapter {
        Chapter(
            id: id,
            title: title,
            chapterNumber: chapterNumber,
            startTime: startTime,
            duration: duration,
            audioResourceName: audioResourceName,
            remoteAudioURL: remoteAudioURL,
            transcriptSegments: [],
            fullText: text
        ).ensuringTranscript()
    }

    private static func defaultTextFromSegments(_ segments: [TranscriptSegment]) -> String {
        segments.map { $0.text }.joined(separator: "\n\n")
    }
}
