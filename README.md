# AudioBy 🎧 (Production-Ready Swift / SwiftUI Audiobook App)

AudioBy is a native, production-ready iOS audiobook application built with modern Swift 5.9+ / Swift 6 and SwiftUI. Inspired by the best UX and audio engineering patterns from **Audible, Storytel, Spotify Audiobooks, Libby, and Blinkist/Headway**, AudioBy features live open API streaming, offline downloads, lock-screen controls, variable scrubbing rates, sleep timer with audio ducking & shake-to-extend, driving Car Mode, and habit streak tracking.

---

## 🌟 Key Features

### 1. Live Data Pipeline & Open Catalog
- **Open API Ingestion**: Live streaming connection to the **LibriVox API** & **Internet Archive CDN** for tens of thousands of free public domain audiobooks.
- **Rich Curated Offline Fallbacks**: Bundled tracks across Fiction, Sci-Fi, Leadership, Mindset, Philosophy, and Tech.
- **Dynamic Category & Search Filters**: Filter by genre, search query debounce, and duration length (<1h, 1-3h, 3-6h, 6+h).
- **30-Second Sample Previews**: Instant audio preview mode without wiping or disrupting active listening queue progress.

### 2. Native Audio Player Engine & Audible-Grade Controls
- **AVFoundation Playback Core**: `AVPlayer` + `AVAudioSession` supporting background audio streaming (`UIBackgroundModes: audio`).
- **Pitch-Preserving Speed Adjustment**: 0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 1.75x, 2.0x, 2.5x, 3.0x using time-domain pitch compensation.
- **Fine-Tune Scrubber**: Drag vertically to engage Hi-Speed, Half-Speed (0.5x), Quarter-Speed (0.25x), or Fine Scrubbing (0.1x).
- **Auto-Rewind on Resume**: Automatically rewinds 10s after long pauses (>5 mins) so listeners instantly recover context.
- **Voice Clarity Boost EQ**: Enhances speech frequencies and cuts background noise.
- **Smart Sleep Timer**: 5m to 60m / End of Chapter with smooth 30s volume ducking (fade-out) and accelerometer shake-to-extend (+5m).
- **Dedicated Car Mode**: High-contrast, distraction-free oversized drive player for driving safety.
- **Lock Screen & Control Center Integration**: `MPNowPlayingInfoCenter` and `MPRemoteCommandCenter` with chapter scrubbing.

### 3. Personal Library & Offline Storage Manager
- **Multi-Shelf Library**: "Currently Listening", "Saved / Favorites", "Downloaded (Offline)", and "Finished".
- **Background Offline Downloader**: `URLSessionDownloadTask` pipeline saving audio to `Application Support/Audiobooks/{bookId}/`.
- **Storage Quota Inspection**: Live MB/GB storage meter with "Clear Offline Cache" action.
- **Bookmarks & Quote Notebook**: Timestamped notes and jump-to functionality.

### 4. Listening Habits & Daily Streaks
- **Daily Streak Tracker**: Visual streak flame banner (e.g. 12-day streak 🔥).
- **Daily Goal Meter**: Customizable 15m / 30m / 45m / 60m daily targets with real-time progress.
- **Weekly Activity Chart**: Day-by-day listening minutes breakdown.
- **Milestone Achievements**: Unlockable badges ("Night Owl", "10-Hour Club", "Polymath", "Marathoner").

---

## 📂 Project Architecture

```
AudioBy/
├── App/
│   ├── AudioByApp.swift                # App entry point & AVAudioSession setup
│   └── MainTabView.swift               # 5-Tab dock navigation & persistent mini-player
├── Models/
│   ├── Audiobook.swift                 # Audiobook entity & categories
│   ├── Chapter.swift                   # Chapter metadata & streaming URLs
│   ├── Bookmark.swift                  # Timestamped notes & quotes
│   └── PlaybackSpeed.swift             # Pitch-corrected playback speeds (0.5x - 3.5x)
├── Services/
│   ├── AudiobookAPIService.swift       # LibriVox & Internet Archive REST client
│   ├── AudiobookRepository.swift       # Catalog repository & multi-criteria filters
│   ├── AudioPlayerService.swift        # AVPlayer engine, fine scrubbing & voice EQ
│   ├── DownloadManager.swift           # Offline storage & background download tasks
│   ├── NowPlayingManager.swift         # Lock screen MPNowPlayingInfoCenter & MPRemote
│   ├── SleepTimerService.swift         # Sleep timer with ducking & shake-to-extend
│   └── StorageService.swift            # Persistence for progress, streaks & bookmarks
├── UI/
│   ├── Theme/
│   │   └── Theme.swift                 # Glassmorphism tokens & color hex utilities
│   ├── Components/
│   │   ├── CoverArtView.swift          # Gradient artwork with ambient glow
│   │   ├── WaveformVisualizer.swift    # Animated audio spectrum visualizer
│   │   ├── PlaybackSlider.swift        # Precision scrubber with fine-scrubbing indicator
│   │   └── FloatingDockTabBar.swift    # 5-tab floating capsule dock
│   └── Views/
│       ├── Library/
│       │   ├── HomeDashboardView.swift # Featured hero spotlight & Continue Listening
│       │   ├── LibraryView.swift       # Shelves, downloads manager & bookmarks
│       │   └── AudiobookDetailView.swift # Full synopsis, chapter list & download action
│       ├── Discover/
│       │   └── ExploreSearchView.swift # Live debounced search & duration filters
│       ├── Activity/
│       │   └── ActivityStatsView.swift # Streaks, weekly bar chart & achievements
│       ├── Settings/
│       │   └── ProfileDetailsView.swift # Audio engine settings & storage manager
│       └── Player/
│           ├── FullScreenPlayerView.swift # Luxury modal player with waveform & voice boost
│           ├── CarModeView.swift       # High-contrast distraction-free driving UI
│           ├── MiniPlayerView.swift    # Bottom floating player bar
│           ├── ChapterListSheet.swift  # Chapter navigation sheet
│           ├── SpeedPickerSheet.swift  # Playback speed picker
│           └── SleepTimerSheet.swift   # Sleep timer options sheet
└── AudioByTests/
    ├── AudioPlayerTests.swift          # Unit tests for player, formatting & storage
    └── AudiobookRepositoryTests.swift  # Unit tests for repository, API & filters
```

---

## 🚀 Quick Setup & Build

1. **Generate Xcode Project**:
   ```bash
   xcodegen generate
   ```

2. **Open in Xcode**:
   ```bash
   open AudioBy.xcodeproj
   ```
   Select any iOS Simulator (e.g. `iPhone 17 Pro`) and press **Cmd + R** to run!
