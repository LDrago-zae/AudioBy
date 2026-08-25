import Foundation

/// Represents a user saved bookmark/quote with a timestamp in a specific audiobook.
public struct Bookmark: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let audiobookId: String
    public let chapterId: String
    public let chapterTitle: String
    public let timestamp: TimeInterval
    public var note: String
    public let createdAt: Date

    public init(
        id: String = UUID().uuidString,
        audiobookId: String,
        chapterId: String,
        chapterTitle: String,
        timestamp: TimeInterval,
        note: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.audiobookId = audiobookId
        self.chapterId = chapterId
        self.chapterTitle = chapterTitle
        self.timestamp = timestamp
        self.note = note
        self.createdAt = createdAt
    }

    public var formattedTimestamp: String {
        let totalSeconds = Int(timestamp)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
