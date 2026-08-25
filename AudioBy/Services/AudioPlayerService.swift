import Foundation
import AVFoundation
import MediaPlayer
import Observation

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

    // MARK: - Private Engine Properties
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private let sleepTimerService = SleepTimerService()
    private let storageService = StorageService.shared
    private let nowPlayingManager = NowPlayingManager.shared

    public override init() {
        super.init()
        setupAudioSession()
        setupRemoteCommands()
        setupInterruptionNotifications()
        self.bookmarks = storageService.loadBookmarks()
    }

    deinit {
        removeTimeObserver()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Audio Session Setup

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])
            try session.setActive(true)
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

        // Pause if headphones are unplugged
        if reason == .oldDeviceUnavailable {
            pause()
        }
    }

    // MARK: - Playback Control

    public func loadAudiobook(_ book: Audiobook, chapterIndex: Int = 0, autoPlay: Bool = true) {
        self.currentBook = book
        self.currentChapterIndex = max(0, min(chapterIndex, book.chapters.count - 1))
        self.isMiniPlayerVisible = true

        loadCurrentChapter(autoPlay: autoPlay)
    }

    private func loadCurrentChapter(autoPlay: Bool) {
        guard let book = currentBook, !book.chapters.isEmpty else { return }
        let chapter = book.chapters[currentChapterIndex]

        removeTimeObserver()
        player?.pause()
        player = nil

        var playerItem: AVPlayerItem?

        // 1. Try bundled resource file
        if let resourceName = chapter.audioResourceName,
           let path = Bundle.main.path(forResource: resourceName, ofType: "m4a") {
            let url = URL(fileURLWithPath: path)
            playerItem = AVPlayerItem(url: url)
        } else if let resourceName = chapter.audioResourceName,
                  let path = Bundle.main.path(forResource: resourceName, ofType: "mp3") {
            let url = URL(fileURLWithPath: path)
            playerItem = AVPlayerItem(url: url)
        } else if let remoteURL = chapter.remoteAudioURL {
            playerItem = AVPlayerItem(url: remoteURL)
        }

        guard let item = playerItem else {
            // Fallback for demo: estimate duration from chapter model
            self.duration = chapter.duration
            self.currentTime = 0
            self.isPlaying = false
            return
        }

        player = AVPlayer(playerItem: item)
        player?.automaticallyWaitsToMinimizeStalling = true

        // Observe duration
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let assetDuration = try await item.asset.load(.duration)
                let seconds = CMTimeGetSeconds(assetDuration)
                if seconds > 0 && !seconds.isNaN {
                    await MainActor.run {
                        self.duration = seconds
                    }
                } else {
                    await MainActor.run {
                        self.duration = chapter.duration
                    }
                }
            } catch {
                await MainActor.run {
                    self.duration = chapter.duration
                }
            }
        }

        // Add periodic observer
        let interval = CMTime(seconds: 0.25, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            let currentSeconds = CMTimeGetSeconds(time)
            if !currentSeconds.isNaN {
                self.currentTime = currentSeconds
                self.syncProgress()
            }
        }

        // Observe track finished
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )

        if autoPlay {
            play()
        } else {
            updateNowPlaying()
        }
    }

    @objc private func playerItemDidReachEnd(notification: Notification) {
        if let book = currentBook, currentChapterIndex < book.chapters.count - 1 {
            nextChapter()
        } else {
            pause()
            currentTime = 0
            seek(to: 0)
        }
    }

    public func play() {
        guard let player = player else {
            if currentBook != nil {
                loadCurrentChapter(autoPlay: true)
            }
            return
        }
        player.rate = playbackSpeed.rawValue
        isPlaying = true
        updateNowPlaying()
    }

    public func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlaying()
    }

    public func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    public func seek(to time: TimeInterval) {
        let clamped = max(0, min(time, duration > 0 ? duration : 3600))
        currentTime = clamped
        let cmTime = CMTime(seconds: clamped, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            self?.updateNowPlaying()
        }
    }

    public func jump(by seconds: TimeInterval) {
        let newTime = currentTime + seconds
        seek(to: newTime)
    }

    public func setSpeed(_ speed: PlaybackSpeed) {
        self.playbackSpeed = speed
        if isPlaying {
            player?.rate = speed.rawValue
        }
        updateNowPlaying()
    }

    public func nextChapter() {
        guard let book = currentBook else { return }
        if currentChapterIndex < book.chapters.count - 1 {
            currentChapterIndex += 1
            loadCurrentChapter(autoPlay: isPlaying)
        }
    }

    public func previousChapter() {
        // If played more than 3 seconds, restart current chapter, otherwise go to previous
        if currentTime > 3.0 {
            seek(to: 0)
        } else if currentChapterIndex > 0 {
            currentChapterIndex -= 1
            loadCurrentChapter(autoPlay: isPlaying)
        } else {
            seek(to: 0)
        }
    }

    // MARK: - Bookmarks

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

    public func deleteBookmark(_ bookmark: Bookmark) {
        bookmarks.removeAll { $0.id == bookmark.id }
        storageService.saveBookmarks(bookmarks)
    }

    public func bookmarksForCurrentBook() -> [Bookmark] {
        guard let book = currentBook else { return [] }
        return bookmarks.filter { $0.audiobookId == book.id }
    }

    // MARK: - Helpers

    public var currentChapter: Chapter? {
        guard let book = currentBook, currentChapterIndex >= 0, currentChapterIndex < book.chapters.count else { return nil }
        return book.chapters[currentChapterIndex]
    }

    public var remainingChapterTime: TimeInterval {
        max(0, duration - currentTime)
    }

    private func syncProgress() {
        guard let book = currentBook else { return }
        let chapterRatio = duration > 0 ? (currentTime / duration) : 0.0
        let overallProgress = (Double(currentChapterIndex) + chapterRatio) / Double(max(1, book.chapters.count))
        storageService.saveProgress(
            bookId: book.id,
            chapterIndex: currentChapterIndex,
            position: currentTime,
            progressRatio: overallProgress
        )
        updateNowPlaying()
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
