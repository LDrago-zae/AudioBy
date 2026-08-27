import Foundation

/// Represents user feedback and reviews for an audiobook.
public struct BookReview: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let userName: String
    public let userAvatar: String?
    public let rating: Double
    public let comment: String
    public let dateString: String
    public let helpfulCount: Int

    public init(
        id: String = UUID().uuidString,
        userName: String,
        userAvatar: String? = nil,
        rating: Double = 5.0,
        comment: String,
        dateString: String = "2 days ago",
        helpfulCount: Int = 12
    ) {
        self.id = id
        self.userName = userName
        self.userAvatar = userAvatar
        self.rating = rating
        self.comment = comment
        self.dateString = dateString
        self.helpfulCount = helpfulCount
    }
}
