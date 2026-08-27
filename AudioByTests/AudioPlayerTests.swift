import XCTest
@testable import AudioBy

final class AudioPlayerTests: XCTestCase {

    func testChapterDurationFormatting() {
        let chapter = Chapter(
            title: "Intro",
            chapterNumber: 1,
            startTime: 0,
            duration: 125.0
        )
        XCTAssertEqual(chapter.formattedDuration, "2:05")

        let longChapter = Chapter(
            title: "Long Story",
            chapterNumber: 2,
            startTime: 125,
            duration: 3900.0
        )
        XCTAssertEqual(longChapter.formattedDuration, "1h 5m")
    }

    func testBookmarkTimestampFormatting() {
        let bookmark = Bookmark(
            audiobookId: "b1",
            chapterId: "c1",
            chapterTitle: "Chapter 1",
            timestamp: 125.0,
            note: "A memorable quote."
        )
        XCTAssertEqual(bookmark.formattedTimestamp, "02:05")
        XCTAssertEqual(bookmark.note, "A memorable quote.")
    }

    func testPlaybackSpeedEnum() {
        XCTAssertEqual(PlaybackSpeed.normal.rawValue, 1.0)
        XCTAssertEqual(PlaybackSpeed.double.rawValue, 2.0)
        XCTAssertEqual(PlaybackSpeed.oneAndHalf.shortTitle, "1.5×")
    }

    func testSleepTimerOptions() {
        let fiveMin = SleepTimerOption.fiveMinutes
        XCTAssertEqual(fiveMin.duration, 300)

        let off = SleepTimerOption.off
        XCTAssertNil(off.duration)
    }

    func testStorageServiceStats() {
        let defaults = UserDefaults(suiteName: "AudioBy.Tests.\(UUID().uuidString)")!
        let storage = StorageService(userDefaults: defaults)
        storage.recordListeningSeconds(60)
        let stats = storage.loadStats()
        XCTAssertGreaterThanOrEqual(stats.totalMinutesListened, 1)
        XCTAssertGreaterThanOrEqual(stats.streakDays, 1)
    }

    func testDownloadManagerStorage() {
        let dm = DownloadManager.shared
        XCTAssertNotNil(dm.formattedStorageUsed)
    }
}
