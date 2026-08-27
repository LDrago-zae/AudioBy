import Foundation
import AVFoundation
import MediaPlayer
import Observation
import UIKit

public enum PlaybackNarrationMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case nativeTTS = "Native TTS Voice"
    case streaming = "Human Narration"

    public var id: String { rawValue }
}

@Observable
public final class AudioPlayerService: NSObject, @unchecked Sendable {
    public static let shared = AudioPlayerService()

    // MARK: - Published State
    public var currentBook: Audiobook?
    public var currentChapterIndex: Int = 0
    public var isPlaying: Bool = false
    public var isBuffering: Bool = false
    public var currentTime: TimeInterval = 0
    public var duration: TimeInterval = 0
    public var playbackSpeed: PlaybackSpeed = .normal
    public var bookmarks: [Bookmark] = []
    public var isMiniPlayerVisible: Bool = false
    public var isFullScreenPlayerPresented: Bool = false
    public var isCarModePresented: Bool = false
    public var narrationMode: PlaybackNarrationMode = .streaming
    public var playbackError: String?
    public var isVocalClarityBoosted: Bool = false {
        didSet {
            applyVocalClarity()
        }
    }

    // Scrubbing speed state (1x, 0.5x, 0.25x, 0.1x)
    public var currentScrubbingRate: Double = 1.0
    public var isScrubbing: Bool = false

    // Sample Preview State
    public var isPlayingSamplePreview: Bool = false
    public var previewBook: Audiobook?

    // MARK: - Private Engine Properties
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var ttsProgressTimer: Timer?
    public let sleepTimerService = SleepTimerService()
    private let storageService = StorageService.shared
    private let nowPlayingManager = NowPlayingManager.shared
    private let downloadManager = DownloadManager.shared
    private let ttsService = TTSEngineService.shared

    // Auto-rewind tracking
    private var lastPausedTimestamp: Date?
    private var accumulatedListeningSeconds: TimeInterval = 0
    private var lastListeningTick: Date?

    public override init() {
        super.init()
        setupAudioSession()
        setupRemoteCommands()
        setupInterruptionNotifications()
        self.bookmarks = storageService.loadBookmarks()
    }

    deinit {
        removeTimeObserver()
        ttsProgressTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Audio Session Setup

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.allowAirPlay, .allowBluetoothHFP, .allowBluetoothA2DP])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up AVAudioSession: \(error)")
        }
    }

    private func setupRemoteCommands() {
        nowPlayingManager.configureRemoteCommands(
            onPlay: { [weak self] in self?.play() },
            onPause: { [weak self] in self?.pause() },
            onTogglePlayPause: { [weak self] in self?.togglePlayPause() },
            onSkipForward: { [weak self] interval in self?.jump(by: interval) },
            onSkipBackward: { [weak self] interval in self?.jump(by: -interval) },
            onNextTrack: { [weak self] in self?.nextChapter() },
            onPreviousTrack: { [weak self] in self?.previousChapter() },
            onSeek: { [weak self] position in self?.seek(to: position) },
            onChangePlaybackRate: { [weak self] rate in
                if let speed = PlaybackSpeed(rawValue: rate) {
                    self?.setSpeed(speed)
                }
            }
        )
    }

    private func setupInterruptionNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    @objc private func handleAudioInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            pause()
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    play()
                }
            }
        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        if reason == .oldDeviceUnavailable {
            pause()
        }
    }

    // MARK: - Playback Control

    public func playAudiobook(_ book: Audiobook, chapterIndex: Int = 0, autoPlay: Bool = true, forceTTS: Bool = false) {
        Task { @MainActor in
            var playable = AudiobookRepository.shared.audiobooks.first(where: { $0.id == book.id }) ?? book
            if playable.chapters.isEmpty {
                self.isBuffering = true
                self.playbackError = nil
                _ = await AudiobookRepository.shared.loadLiveChapters(for: playable.id)
                playable = AudiobookRepository.shared.audiobooks.first(where: { $0.id == book.id }) ?? playable
                self.isBuffering = false
            }
            if playable.chapters.isEmpty {
                self.currentBook = playable
                self.isMiniPlayerVisible = true
                self.playbackError = AudiobookRepository.shared.chapterErrors[playable.id] ?? "Chapters could not be loaded. Open the title and tap Retry."
                return
            }
            self.loadAudiobook(playable, chapterIndex: chapterIndex, autoPlay: autoPlay, forceTTS: forceTTS)
        }
    }

    public func loadAudiobook(_ book: Audiobook, chapterIndex: Int = 0, autoPlay: Bool = true, forceTTS: Bool = false) {
        if isPlayingSamplePreview {
            dismissSamplePreview()
        }

        self.playbackError = nil
        self.currentBook = book
        self.currentChapterIndex = max(0, min(chapterIndex, max(book.chapters.count - 1, 0)))
        self.isMiniPlayerVisible = true

        if forceTTS {
            self.narrationMode = .nativeTTS
        } else if book.hasHumanNarration {
            let chapterText = book.chapters.indices.contains(currentChapterIndex) ? book.chapters[currentChapterIndex].fullText : ""
            if narrationMode == .nativeTTS && chapterText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.narrationMode = .streaming
            }
        } else {
            self.narrationMode = .nativeTTS
        }

        loadCurrentChapter(autoPlay: autoPlay)
    }

    public func playSamplePreview(for book: Audiobook) {
        Task { @MainActor in
            var previewSource = AudiobookRepository.shared.audiobooks.first(where: { $0.id == book.id }) ?? book
            if previewSource.chapters.isEmpty {
                _ = await AudiobookRepository.shared.loadLiveChapters(for: previewSource.id)
                previewSource = AudiobookRepository.shared.audiobooks.first(where: { $0.id == book.id }) ?? previewSource
            }
            guard let chapter = previewSource.chapters.first else {
                self.playbackError = "No sample is available until chapters finish loading."
                return
            }

            self.previewBook = previewSource
            self.isPlayingSamplePreview = true
            self.playbackError = nil

            self.removeTimeObserver()
            self.player?.pause()
            self.player = nil
            self.ttsProgressTimer?.invalidate()

            if let remoteURL = chapter.remoteAudioURL {
                let item = AVPlayerItem(url: remoteURL)
                item.audioTimePitchAlgorithm = .timeDomain
                self.player = AVPlayer(playerItem: item)
                self.duration = min(max(chapter.duration, 30), 30)
                self.currentTime = 0
                self.isPlaying = true
                self.player?.play()
                DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
                    guard let self, self.isPlayingSamplePreview else { return }
                    self.dismissSamplePreview()
                }
                return
            }

            let sampleSnippet = chapter.fullText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !sampleSnippet.isEmpty else {
                self.isPlayingSamplePreview = false
                self.playbackError = "This title has no sample text or audio yet."
                return
            }
            self.ttsService.speak(text: String(sampleSnippet.prefix(400)), bookTitle: previewSource.title, chapterTitle: "30-Second Sample")
            self.duration = 30.0
            self.currentTime = 0
            self.isPlaying = true
        }
    }

    public func dismissSamplePreview() {
        guard isPlayingSamplePreview else { return }
        ttsService.stop()
        ttsProgressTimer?.invalidate()
        isPlayingSamplePreview = false
        previewBook = nil
        isPlaying = false
        currentTime = 0
    }

    private func loadCurrentChapter(autoPlay: Bool) {
        guard let book = currentBook, !book.chapters.isEmpty else {
            playbackError = "No chapters are loaded for this title yet."
            return
        }
        let chapter = book.chapters[currentChapterIndex]
        playbackError = nil
        isBuffering = true

        removeTimeObserver()
        player?.pause()
        player = nil
        ttsProgressTimer?.invalidate()
        ttsService.stop()

        let hasText = !chapter.fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let wantsTTS = narrationMode == .nativeTTS && hasText

        if wantsTTS {
            playViaTTS(chapter: chapter, book: book, autoPlay: autoPlay)
            return
        }

        var playerItem: AVPlayerItem?
        if let localURL = downloadManager.localURLForChapter(bookId: book.id, chapterNumber: chapter.chapterNumber) {
            playerItem = AVPlayerItem(url: localURL)
        } else if let remoteURL = chapter.remoteAudioURL {
            playerItem = AVPlayerItem(url: remoteURL)
        }

        guard let item = playerItem else {
            if hasText {
                playViaTTS(chapter: chapter, book: book, autoPlay: autoPlay)
            } else {
                isBuffering = false
                playbackError = "This chapter has no playable audio. Tap Retry on the book page."
            }
            return
        }

        item.audioTimePitchAlgorithm = .timeDomain
        player = AVPlayer(playerItem: item)
        player?.automaticallyWaitsToMinimizeStalling = true
        applyVocalClarity()

        if book.currentPosition > 0 && book.currentChapterIndex == currentChapterIndex && currentTime == 0 {
            let cmTime = CMTime(seconds: book.currentPosition, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
            self.currentTime = book.currentPosition
        }

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let assetDuration = try await item.asset.load(.duration)
                let seconds = CMTimeGetSeconds(assetDuration)
                await MainActor.run {
                    self.duration = (seconds > 0 && !seconds.isNaN) ? seconds : chapter.duration
                }
            } catch {
                await MainActor.run {
                    self.duration = chapter.duration
                }
            }
        }

        let interval = CMTime(seconds: 0.25, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            let currentSeconds = CMTimeGetSeconds(time)
            if !currentSeconds.isNaN {
                self.currentTime = currentSeconds
                self.isBuffering = self.player?.timeControlStatus == .waitingToPlayAtSpecifiedRate
                self.syncProgress()
                self.trackListeningHabitTime()
            }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemFailed),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: item
        )

        if autoPlay {
            play()
        } else {
            isBuffering = false
            updateNowPlaying()
        }
    }

    private func playViaTTS(chapter: Chapter, book: Audiobook, autoPlay: Bool) {
        let text = chapter.fullText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            isBuffering = false
            playbackError = "No chapter text is available for voice playback."
            return
        }

        self.duration = max(chapter.duration, 60.0)
        self.currentTime = 0
        self.isBuffering = false

        if autoPlay {
            ttsService.speak(text: text, bookTitle: book.title, chapterTitle: chapter.title)
            self.isPlaying = true
            startTTSTimer()
        } else {
            self.isPlaying = false
        }
        updateNowPlaying()
    }

    private func startTTSTimer() {
        ttsProgressTimer?.invalidate()
        ttsProgressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.ttsService.isPlaying {
                self.currentTime += 0.5
                self.syncProgress()
                self.trackListeningHabitTime()
                if self.currentTime >= self.duration {
                    self.nextChapter()
                }
            }
        }
    }

    @objc private func playerItemDidReachEnd(notification: Notification) {
        isBuffering = false
        if let book = currentBook, currentChapterIndex < book.chapters.count - 1 {
            nextChapter()
        } else {
            pause()
            currentTime = 0
            seek(to: 0)
        }
    }

    @objc private func playerItemFailed(notification: Notification) {
        isBuffering = false
        let underlying = (notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error)?.localizedDescription
        playbackError = underlying ?? "Streaming failed. Check your connection and retry."
        isPlaying = false
    }

    public func play() {
        if ttsService.isPaused {
            ttsService.resume()
            isPlaying = true
            startTTSTimer()
            updateNowPlaying()
            return
        }

        guard let player = player else {
            if let book = currentBook {
                loadAudiobook(book, chapterIndex: currentChapterIndex, autoPlay: true)
            }
            return
        }

        if let pausedAt = lastPausedTimestamp, Date().timeIntervalSince(pausedAt) > 300, currentTime > 10 {
            jump(by: -10)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
        lastPausedTimestamp = nil

        player.rate = playbackSpeed.rawValue
        isPlaying = true
        isBuffering = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
        lastListeningTick = Date()
        updateNowPlaying()
    }

    public func pause() {
        if ttsService.isPlaying {
            ttsService.pause()
            isPlaying = false
            ttsProgressTimer?.invalidate()
            lastPausedTimestamp = Date()
            flushListeningHabitTime()
            updateNowPlaying()
            return
        }

        player?.pause()
        isPlaying = false
        lastPausedTimestamp = Date()
        flushListeningHabitTime()
        updateNowPlaying()
    }

    public func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    public func seek(to seconds: TimeInterval) {
        let clamped = max(0, min(seconds, duration))
        currentTime = clamped

        if let player = player {
            let targetTime = CMTime(seconds: clamped, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
                self?.updateNowPlaying()
            }
        }
        syncProgress()
    }

    public func jump(by seconds: TimeInterval) {
        seek(to: currentTime + seconds)
    }

    public func setSpeed(_ speed: PlaybackSpeed) {
        self.playbackSpeed = speed
        if isPlaying {
            player?.rate = speed.rawValue
        }
        updateNowPlaying()
    }

    public func setSleepTimer(_ option: SleepTimerOption) {
        sleepTimerService.setTimer(option: option) { [weak self] in
            self?.pause()
        }
    }

    public func nextChapter() {
        guard let book = currentBook, currentChapterIndex < book.chapters.count - 1 else { return }
        currentChapterIndex += 1
        currentTime = 0
        loadCurrentChapter(autoPlay: isPlaying)
    }

    public func previousChapter() {
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        guard currentChapterIndex > 0 else {
            seek(to: 0)
            return
        }
        currentChapterIndex -= 1
        currentTime = 0
        loadCurrentChapter(autoPlay: isPlaying)
    }

    public func updateChaptersIfCurrent(bookId: String, chapters: [Chapter]) {
        guard currentBook?.id == bookId, !chapters.isEmpty else { return }
        currentBook?.chapters = chapters
        if currentChapterIndex >= chapters.count {
            currentChapterIndex = max(0, chapters.count - 1)
        }
    }

    public var currentChapter: Chapter? {
        guard let book = currentBook,
              currentChapterIndex >= 0 && currentChapterIndex < book.chapters.count else { return nil }
        return book.chapters[currentChapterIndex]
    }

    public func addBookmark(note: String = "") {
        guard let book = currentBook, let chapter = currentChapter else { return }
        let bookmark = Bookmark(
            audiobookId: book.id,
            chapterId: chapter.id,
            chapterTitle: chapter.title,
            timestamp: currentTime,
            note: note
        )
        bookmarks.insert(bookmark, at: 0)
        storageService.saveBookmarks(bookmarks)
    }

    private func applyVocalClarity() {
        setupAudioSession()
    }

    private func syncProgress() {
        guard let book = currentBook, duration > 0 else { return }
        let ratio = currentTime / duration
        storageService.saveProgress(bookId: book.id, chapterIndex: currentChapterIndex, position: currentTime, progressRatio: ratio)
    }

    private func trackListeningHabitTime() {
        guard isPlaying else { return }
        let now = Date()
        if let last = lastListeningTick {
            let delta = now.timeIntervalSince(last)
            if delta > 0 && delta < 5 {
                accumulatedListeningSeconds += delta
                if accumulatedListeningSeconds >= 60 {
                    storageService.recordListeningSeconds(60)
                    accumulatedListeningSeconds -= 60
                }
            }
        }
        lastListeningTick = now
    }

    private func flushListeningHabitTime() {
        if accumulatedListeningSeconds >= 10 {
            storageService.recordListeningSeconds(accumulatedListeningSeconds)
            accumulatedListeningSeconds = 0
        }
        lastListeningTick = nil
    }

    private func updateNowPlaying() {
        nowPlayingManager.updateNowPlaying(
            book: currentBook,
            chapter: currentChapter,
            currentTime: currentTime,
            duration: duration,
            playbackRate: playbackSpeed.rawValue,
            isPlaying: isPlaying
        )
    }

    private func removeTimeObserver() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }
}
