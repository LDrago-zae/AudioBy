import Foundation
import MediaPlayer
import UIKit

/// Coordinates Lock Screen & Control Center Now Playing information and remote command handling.
public final class NowPlayingManager: @unchecked Sendable {
    public static let shared = NowPlayingManager()

    private init() {}

    public func configureRemoteCommands(
        onPlay: @escaping () -> Void,
        onPause: @escaping () -> Void,
        onTogglePlayPause: @escaping () -> Void,
        onSkipForward: @escaping (TimeInterval) -> Void,
        onSkipBackward: @escaping (TimeInterval) -> Void,
        onNextTrack: @escaping () -> Void,
        onPreviousTrack: @escaping () -> Void,
        onSeek: @escaping (TimeInterval) -> Void,
        onChangePlaybackRate: @escaping (Float) -> Void
    ) {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Play / Pause / Toggle
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { _ in
            onPlay()
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { _ in
            onPause()
            return .success
        }

        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { _ in
            onTogglePlayPause()
            return .success
        }

        // Skip 15s forward & backward
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { event in
            if let skipEvent = event as? MPSkipIntervalCommandEvent {
                onSkipForward(skipEvent.interval)
            } else {
                onSkipForward(15)
            }
            return .success
        }

        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { event in
            if let skipEvent = event as? MPSkipIntervalCommandEvent {
                onSkipBackward(skipEvent.interval)
            } else {
                onSkipBackward(15)
            }
            return .success
        }

        // Next / Previous Chapter
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { _ in
            onNextTrack()
            return .success
        }

        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { _ in
            onPreviousTrack()
            return .success
        }

        // Scrubbing / Seek
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { event in
            if let positionEvent = event as? MPChangePlaybackPositionCommandEvent {
                onSeek(positionEvent.positionTime)
                return .success
            }
            return .commandFailed
        }

        // Playback Rate
        commandCenter.changePlaybackRateCommand.isEnabled = true
        commandCenter.changePlaybackRateCommand.supportedPlaybackRates = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5]
        commandCenter.changePlaybackRateCommand.addTarget { event in
            if let rateEvent = event as? MPChangePlaybackRateCommandEvent {
                onChangePlaybackRate(rateEvent.playbackRate)
                return .success
            }
            return .commandFailed
        }
    }

    public func updateNowPlaying(
        book: Audiobook?,
        chapter: Chapter?,
        currentTime: TimeInterval,
        duration: TimeInterval,
        playbackRate: Float,
        isPlaying: Bool
    ) {
        guard let book = book else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = chapter?.title ?? book.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = book.author
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = book.title
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration > 0 ? duration : (chapter?.duration ?? 0)
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackRate : 0.0
        nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0

        if let chapter = chapter {
            nowPlayingInfo[MPMediaItemPropertyAlbumTrackNumber] = chapter.chapterNumber
            nowPlayingInfo[MPMediaItemPropertyAlbumTrackCount] = book.chapters.count
        }

        // Dynamic artwork placeholder rendering
        let artworkImage = generateArtworkImage(title: book.title, author: book.author)
        nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: CGSize(width: 512, height: 512)) { _ in
            return artworkImage
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    private func generateArtworkImage(title: String, author: String) -> UIImage {
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)

            // Gradient background
            let colors = [
                UIColor(red: 0.15, green: 0.12, blue: 0.28, alpha: 1.0).cgColor,
                UIColor(red: 0.05, green: 0.04, blue: 0.10, alpha: 1.0).cgColor
            ]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0]) {
                context.cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            }

            // Accent bar
            let barRect = CGRect(x: 40, y: 40, width: 8, height: 120)
            UIColor(red: 0.35, green: 0.55, blue: 0.95, alpha: 1.0).setFill()
            UIRectFill(barRect)

            // Title text
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 34, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let titleString = NSAttributedString(string: title, attributes: titleAttributes)
            titleString.draw(in: CGRect(x: 60, y: 40, width: size.width - 100, height: 160))

            // Author text
            let authorAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .medium),
                .foregroundColor: UIColor.lightGray
            ]
            let authorString = NSAttributedString(string: "by \(author)", attributes: authorAttributes)
            authorString.draw(in: CGRect(x: 60, y: 190, width: size.width - 100, height: 40))

            // Badge
            let badgeAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                .foregroundColor: UIColor.cyan
            ]
            let badgeString = NSAttributedString(string: "AudioBy Exclusive", attributes: badgeAttributes)
            badgeString.draw(in: CGRect(x: 60, y: size.height - 80, width: size.width - 100, height: 30))
        }
    }
}
