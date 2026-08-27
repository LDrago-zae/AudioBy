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
    public let coverImageURL: URL?
    public let category: AudiobookCategory
    public let rating: Double
    public let reviewCount: Int
    public var chapters: [Chapter]
    public let reviews: [BookReview]
    public var archiveIdentifier: String?
    public var gutenbergId: Int?
    public var textURL: URL?
    public var catalogSource: String
    public var listenCount: Int
    public var estimatedDuration: TimeInterval
    public var isFavorite: Bool
    public var progress: Double
    public var currentChapterIndex: Int
    public var currentPosition: TimeInterval

    public init(
        id: String = UUID().uuidString,
        title: String,
        author: String,
        narrator: String,
        summary: String,
        coverGradientColors: [String] = ["#0d150f", "#10c76b"],
        coverImageURL: URL? = nil,
        category: AudiobookCategory = .fiction,
        rating: Double = 0,
        reviewCount: Int = 0,
        chapters: [Chapter] = [],
        reviews: [BookReview] = [],
        archiveIdentifier: String? = nil,
        gutenbergId: Int? = nil,
        textURL: URL? = nil,
        catalogSource: String = "",
        listenCount: Int = 0,
        estimatedDuration: TimeInterval = 0,
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
        self.coverImageURL = coverImageURL
        self.category = category
        self.rating = rating
        self.reviewCount = reviewCount
        self.chapters = chapters
        self.reviews = reviews
        self.archiveIdentifier = archiveIdentifier
        self.gutenbergId = gutenbergId
        self.textURL = textURL
        self.catalogSource = catalogSource
        self.listenCount = listenCount
        self.estimatedDuration = estimatedDuration
        self.isFavorite = isFavorite
        self.progress = progress
        self.currentChapterIndex = currentChapterIndex
        self.currentPosition = currentPosition
    }

    public var hasHumanNarration: Bool {
        archiveIdentifier != nil || chapters.contains { $0.remoteAudioURL != nil }
    }

    public var hasDownloadableAudio: Bool {
        chapters.contains { $0.remoteAudioURL != nil }
    }

    public var totalDuration: TimeInterval {
        let chapterTotal = chapters.reduce(0) { $0 + $1.duration }
        return chapterTotal > 0 ? chapterTotal : estimatedDuration
    }

    public var formattedTotalDuration: String {
        let total = Int(totalDuration)
        guard total > 0 else { return "—" }
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        } else {
            return "\(minutes) min"
        }
    }

    public var formattedListenCount: String {
        if listenCount >= 1000 {
            return String(format: "%.1fk", Double(listenCount) / 1000.0)
        }
        return "\(listenCount)"
    }

    public var currentChapter: Chapter? {
        guard currentChapterIndex >= 0 && currentChapterIndex < chapters.count else { return chapters.first }
        return chapters[currentChapterIndex]
    }
}
