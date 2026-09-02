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

2. **ElevenLabs API key (Premium studio voices)** — keep the key out of the app. Copy `AudioBy/Config/Secrets.example.xcconfig` to `AudioBy/Config/Secrets.xcconfig` and set `ELEVENLABS_API_KEY`, or add `ELEVENLABS_API_KEY` under the Xcode scheme (Run → Arguments → Environment Variables). `.env.example` documents the same name. `Secrets.xcconfig` and `.env` are gitignored and never shipped as user-facing settings.

3. **Local catalog (SQLite)** — Explore/search reads a bundled `catalog.fixture.sqlite` (no network). For a full Gutenberg catalog, run the Mac ingest job and host the file:

   ```bash
   cd Tools/catalog-ingest
   python3 -m venv .venv && source .venv/bin/activate
   pip install -r requirements.txt
   python3 ingest_catalog.py --write-fixture ../../AudioBy/Resources/catalog.fixture.sqlite
   # Full rebuild (download dumps yourself first):
   # python3 ingest_catalog.py --gutenberg-rdf rdf-files.tar.zip --ol-dump ol_dump_editions.txt.gz -o catalog.sqlite
   ```

   Host `catalog.sqlite` and set `CATALOG_SQLITE_URL` in `Secrets.xcconfig` or the scheme environment. The app downloads it once (ETag / Last-Modified) into Application Support. Do not parse RDF dumps on-device.

4. **Firebase Auth** — project `audioby-app` is wired via `GoogleService-Info.plist`. This file is **gitignored** (it contains a project API key) — copy `AudioBy/Resources/GoogleService-Info.example.plist` to `AudioBy/Resources/GoogleService-Info.plist` and fill it in, or download the real one from [Firebase Console → Project settings](https://console.firebase.google.com/project/audioby-app/settings/general) → your iOS app. Email/password and Google are enabled. In [Firebase Console → Authentication → Sign-in method](https://console.firebase.google.com/project/audioby-app/authentication/providers), enable **Apple**. Sign in with Apple also needs a paid Apple Developer team in Xcode (Signing & Capabilities), the Sign in with Apple capability, and an Apple ID signed in on the Simulator or device. After enabling Google, re-download the plist if `CLIENT_ID` / `REVERSED_CLIENT_ID` are missing, then set `GID_CLIENT_ID` and `GOOGLE_REVERSED_CLIENT_ID` in `Secrets.xcconfig`.

5. **Open in Xcode**:
   ```bash
   open AudioBy.xcodeproj
   ```
   Select any iOS Simulator (e.g. `iPhone 17 Pro`) and press **Cmd + R** to run!

---

## 💳 Monetization: Subscriptions via StoreKit + RevenueCat

Plus and Premium tiers ([EntitlementService.swift](AudioBy/Services/EntitlementService.swift)) are sold as **native iOS in-app subscriptions**. Apple requires that unlocking features inside a native app go through **StoreKit In-App Purchase** — RevenueCat sits on top of StoreKit as an entitlement/analytics layer, it does not replace Apple as the payment processor and does not change how you get paid. Money always flows: user pays via the App Store → Apple takes its commission (15–30%) → Apple pays out to whatever bank/Payoneer account you configure in App Store Connect.

### 1. Create the subscription products in App Store Connect
In [App Store Connect](https://appstoreconnect.apple.com) → your app → **Monetization → Subscriptions**:
1. Create a Subscription Group (e.g. "AudioBy Plans").
2. Add two auto-renewable subscriptions matching the identifiers already hardcoded in `EntitlementService.swift`:
   - `com.audioby.plus.monthly`
   - `com.audioby.premium.monthly`
3. Set a price for each in your base territory; App Store Connect auto-generates localized prices for every storefront (including Pakistan's PKR pricing tier).
4. Fill in the required subscription display name, description, and review screenshot for each product, then submit them for review alongside your next app build.

### 2. Connect RevenueCat
1. Create a free [RevenueCat](https://app.revenuecat.com) project (free up to $2.5k/mo tracked revenue, then 1%).
2. Under **Project settings → Apps**, add your iOS app and connect it to App Store Connect using an **App Store Connect API Key** (recommended) or your app's shared secret.
3. Under **Entitlements**, create two entitlements named exactly `plus` and `premium` (these identifiers are hardcoded in `EntitlementService.swift`), and attach the matching App Store Connect products to each.
4. Under **Offerings**, create a `default` offering with two Packages, one pointing at `com.audioby.plus.monthly` and one at `com.audioby.premium.monthly`. The app fetches this offering on launch and in the paywall to show live, localized prices.
5. Copy your **Public app-specific API key** (starts with `appl_`) from **Project settings → API keys**, then set `REVENUECAT_API_KEY` in `Secrets.xcconfig` (copy `Secrets.example.xcconfig` if you haven't already).

### 3. Testing without live App Store products
While product review/setup is pending, use the **Debug unlock** control in Settings (`EntitlementService.setDebugTier`) to preview Plus/Premium-gated UI locally without a real purchase. `PaywallView` falls back to placeholder prices ("$9.99"/"$4.99") until RevenueCat successfully fetches your configured offering.

### 4. Getting paid in Pakistan
This is an App Store Connect account setting, not something in this codebase. In **App Store Connect → Agreements, Tax, and Banking**, add your banking details:
- Apple has supported direct PKR bank transfers via partner banks in Pakistan for several years — check if your bank is listed first.
- If your bank isn't supported, a [Payoneer](https://www.payoneer.com) USD receiving account is the common workaround Pakistani developers use to receive Apple's payouts, then withdraw locally.
- RevenueCat itself never touches your money — it only reads purchase/entitlement data from Apple's servers, so there is nothing to configure there for payouts.
