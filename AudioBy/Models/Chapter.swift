import Foundation

/// Represents a chapter within an audiobook.
public struct Chapter: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let chapterNumber: Int
    public let startTime: TimeInterval
    public let duration: TimeInterval
    public let audioResourceName: String?
    public let remoteAudioURL: URL?

    public init(
        id: String = UUID().uuidString,
        title: String,
        chapterNumber: Int,
        startTime: TimeInterval,
        duration: TimeInterval,
        audioResourceName: String? = nil,
        remoteAudioURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.chapterNumber = chapterNumber
        self.startTime = startTime
        self.duration = duration
        self.audioResourceName = audioResourceName
        self.remoteAudioURL = remoteAudioURL
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
}
