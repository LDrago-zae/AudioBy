import Foundation
import SwiftUI

public enum AudiobookCategory: String, CaseIterable, Codable, Sendable {
    case all = "All"
    case technology = "Technology & Science"
    case business = "Business & Leadership"
    case fiction = "Fiction & Sci-Fi"
    case philosophy = "Philosophy & Mind"
    case biography = "Biography & History"

    public var iconName: String {
        switch self {
        case .all: return "books.vertical.fill"
        case .technology: return "cpu.fill"
        case .business: return "chart.line.uptrend.xyaxis"
        case .fiction: return "sparkles"
        case .philosophy: return "brain.head.profile"
        case .biography: return "person.crop.rectangle.stack.fill"
        }
    }
}

public struct Audiobook: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let author: String
    public let narrator: String
    public let summary: String
    public let coverGradientColors: [String]
    public let category: AudiobookCategory
    public let rating: Double
    public let reviewCount: Int
    public let chapters: [Chapter]
    public var isFavorite: Bool
    public var progress: Double // 0.0 to 1.0
    public var currentChapterIndex: Int
    public var currentPosition: TimeInterval

    public init(
        id: String = UUID().uuidString,
        title: String,
        author: String,
        narrator: String,
        summary: String,
        coverGradientColors: [String] = ["#4A00E0", "#8E2DE2"],
        category: AudiobookCategory = .technology,
        rating: Double = 4.8,
        reviewCount: Int = 120,
        chapters: [Chapter] = [],
        isFavorite: Bool = false,
        progress: Double = 0.0,
        currentChapterIndex: Int = 0,
        currentPosition: TimeInterval = 0
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.narrator = narrator
        self.summary = summary
        self.coverGradientColors = coverGradientColors
        self.category = category
        self.rating = rating
        self.reviewCount = reviewCount
        self.chapters = chapters
        self.isFavorite = isFavorite
        self.progress = progress
        self.currentChapterIndex = currentChapterIndex
        self.currentPosition = currentPosition
    }

    public var totalDuration: TimeInterval {
        chapters.reduce(0) { $0 + $1.duration }
    }

    public var formattedTotalDuration: String {
        let total = Int(totalDuration)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        } else {
            return "\(minutes) min"
        }
    }

    public var currentChapter: Chapter? {
        guard currentChapterIndex >= 0 && currentChapterIndex < chapters.count else { return chapters.first }
        return chapters[currentChapterIndex]
    }
}
