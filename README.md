# AudioBy 🎧 (Swift / SwiftUI Audiobook App)

AudioBy is a modern, native iOS audiobook application built 100% in Swift and SwiftUI. It features a complete `AVFoundation` playback engine, lock-screen media integration (`MPNowPlayingInfoCenter` / `MPRemoteCommandCenter`), background audio streaming, bookmarks, sleep timers, and a library management interface.

---

## 🌟 Key Features

- **Native Audio Player Engine**:
  - `AVPlayer` + `AVAudioSession` setup with background playback capability (`UIBackgroundModes: audio`).
  - Lock Screen & Control Center controls (`MPNowPlayingInfoCenter`, `MPRemoteCommandCenter`).
  - Audio interruption handling (phone calls, route changes, headphones disconnect).
  - Variable playback rate (0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 1.75x, 2.0x, 2.5x).
  - Skip forward 30s & skip backward 15s.
  - Sleep timer (5m, 15m, 30m, 45m, 60m, or "End of Chapter").
- **SwiftUI UI & Glassmorphic Design System**:
  - **Full-Screen Player**: Responsive cover art with ambient color glow, waveform visualizer, and precision scrubber bar.
  - **Persistent Mini-Player**: Bottom player floating above tabs with interactive play/pause and progress line.
  - **Library View**: "Continue Listening" carousel, Category filter chips, and 2-column audiobook catalog grid.
  - **Discover & Search**: Live search by title, author, or narrator with trending cards.
  - **Bookmarks & Quotes**: Save timestamped notes and jump right back to exact moments in the audio.
  - **Settings**: Audio preferences (quality, auto-rewind on resume, download over Wi-Fi).
- **Tooling & Build System**:
  - Declarative Xcode project generation via **XcodeGen** (`project.yml`).
  - `Makefile` and `scripts/setup.sh` for one-command builds and tests.
  - Bundled sample audiobook tracks (`sample_chapter1.m4a`, `sample_chapter2.m4a`, etc.) for immediate testing out of the box.

---

## 🚀 Getting Started

### Prerequisites
- macOS Sonoma or macOS Sequoia / Tahoe
- Xcode 15+ / Xcode 16+ / Xcode 26+
- [Homebrew](https://brew.sh) (used to install `xcodegen`)

### Quick Setup & Launch

1. **Generate the Xcode Project**:
   ```bash
   make setup
   # or run
   xcodegen generate
   ```

2. **Open in Xcode**:
   ```bash
   open AudioBy.xcodeproj
   ```
   Select any iOS Simulator (e.g. `iPhone 17 Pro`) and press **Cmd + R** to run!

3. **Build from CLI**:
   ```bash
   make build
   ```

4. **Run Unit Tests**:
   ```bash
   make test
   ```

---

## 📂 Project Structure

```
AudioBy/
├── App/
│   ├── AudioByApp.swift                # App entry point & Audio session startup
│   └── MainTabView.swift               # Tab navigation & persistent mini-player
├── Models/
│   ├── Audiobook.swift                 # Audiobook entity & categories
│   ├── Chapter.swift                   # Chapter metadata & duration helpers
│   ├── Bookmark.swift                  # Timestamped bookmark & user notes
│   └── PlaybackSpeed.swift             # Playback speed enum (0.5x to 2.5x)
├── Services/
│   ├── AudioPlayerService.swift        # Main AVPlayer engine & background playback
│   ├── NowPlayingManager.swift         # Lock screen MPNowPlayingInfoCenter & MPRemote
│   ├── SleepTimerService.swift         # Sleep timer with countdown & auto-pause
│   ├── AudiobookRepository.swift       # Library catalog, search & filtering
│   └── StorageService.swift            # UserDefaults persistence for progress & bookmarks
├── UI/
│   ├── Theme/
│   │   └── Theme.swift                 # Colors, gradients & glassmorphism
│   ├── Components/
│   │   ├── CoverArtView.swift          # Gradient cover art component
│   │   ├── WaveformVisualizer.swift    # Animated dynamic audio waveform
│   │   └── PlaybackSlider.swift        # Interactive precision scrubber
│   └── Views/
│       ├── Library/
│       │   ├── LibraryView.swift       # Main catalog & Continue Listening
│       │   └── AudiobookDetailView.swift # Detailed view & chapter list
│       ├── Discover/
│       │   └── DiscoverView.swift      # Search & spotlight view
│       ├── Bookmarks/
│       │   └── BookmarksView.swift     # Saved bookmarks & quotes
│       ├── Settings/
│       │   └── SettingsView.swift      # Playback & audio preferences
│       └── Player/
│           ├── FullScreenPlayerView.swift # Full-screen modal player
│           ├── MiniPlayerView.swift    # Persistent bottom player bar
│           ├── SleepTimerSheet.swift   # Sleep timer picker sheet
│           ├── SpeedPickerSheet.swift  # Narration speed sheet
│           ├── ChapterListSheet.swift  # Chapter drawer sheet
│           └── AddBookmarkSheet.swift  # Add bookmark modal
├── Resources/
│   ├── Assets.xcassets/                # App icon & theme colors
│   ├── Audio/                          # Bundled sample audio files (.m4a)
│   └── Info.plist                      # UIBackgroundModes audio declaration
├── AudioByTests/
│   ├── AudioPlayerTests.swift          # Unit tests for player logic
│   └── AudiobookRepositoryTests.swift  # Unit tests for catalog filtering
├── project.yml                         # XcodeGen project specification
├── Makefile                            # Build and test shortcuts
└── README.md
```
