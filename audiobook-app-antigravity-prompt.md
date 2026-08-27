# Audiobook App — Build Prompt for Antigravity

## Context
UI is already built (SwiftUI). This spec covers everything needed to make the app **functional**: data sourcing (book metadata, cover art, audio), native TTS as a fallback/generation path, playback engine, offline storage, and background audio. Paste the sections below into Antigravity as-is, or split into smaller tasks per section.

---

## 1. Data Sources — Books, Metadata, Audio

There is no free, legal API for modern commercial audiobooks (Audible has no public API and scraping it violates ToS). The realistic options are:

### A. Public-domain audiobooks (real human narration, free, legal)
- **LibriVox** — the main source. Catalog + audio files:
  - REST API: `https://librivox.org/api/feed/audiobooks/?format=json`
  - Params: `title`, `author`, `genre`, `limit`, `offset`
  - Each result includes chapter-level MP3 URLs (usually hosted on archive.org), narrator, language, run time.
- **Internet Archive** — LibriVox's actual audio host, also has other free audiobooks:
  - Search API: `https://archive.org/advancedsearch.php?q=collection:librivoxaudio&output=json`
  - Metadata API per item: `https://archive.org/metadata/{identifier}` → returns direct file list (mp3/ogg URLs) you can stream/download directly.

### B. Text-only sources (for generating audio via TTS)
- **Project Gutenberg** — full text of public-domain books.
  - Catalog metadata: Gutendex API (community wrapper) `https://gutendex.com/books?search=...` returns download links (`.txt`, `.epub`).
  - You fetch the plain text, chunk it, and feed it to TTS (see §2) to generate your own audio track — useful when LibriVox has no recording of a given book.

### C. Metadata / covers for anything else (non-audio, just book info + cover art)
- **Open Library API** — free, no key: `https://openlibrary.org/search.json?q=...`, covers at `https://covers.openlibrary.org/b/id/{cover_id}-L.jpg`
- **Google Books API** — free tier, needs API key: `https://www.googleapis.com/books/v1/volumes?q=...`

### Recommended pairing
1. Search Open Library / Google Books for metadata + cover.
2. Cross-reference title/author against LibriVox to see if a human-narrated recording exists → use that audio.
3. If not found, pull the text from Gutenberg/Gutendex and generate audio locally with TTS (§2), cache the generated audio file so you only synthesize once.

This gives you a legally clean catalog without needing publisher licensing deals.

---

## 2. Text-to-Speech (when no narrated audio exists)

### Native (free, offline, no API key, ships in-app)
- `AVSpeechSynthesizer` + `AVSpeechUtterance` (AVFoundation)
- Set `utterance.voice = AVSpeechSynthesisVoice(identifier:)` — use enhanced/premium on-device voices if downloaded (Settings → Accessibility → Spoken Content → Voices) for less robotic output.
- To actually **save** synthesized speech as an audio file (not just play live), use `AVSpeechSynthesizer.write(_:toBufferCallback:)` (iOS 16+) which gives you `AVAudioPCMBuffer`s you can write to disk via `AVAudioFile` — this is how you build a cached, seekable audio file per chapter instead of re-synthesizing every playback.
- Pros: free, offline, no rate limits, no legal issues. Cons: quality is noticeably synthetic vs. real narration.

### Higher-quality cloud TTS (optional upgrade path, needs API key + network + cost)
- **ElevenLabs** — most natural-sounding, has a Swift-friendly REST API, per-character pricing.
- **Google Cloud Text-to-Speech** / **Amazon Polly** / **Azure Speech** — cheaper, still solid neural voices, standard REST APIs.
- Pattern: send chapter text → receive MP3/WAV → cache to disk exactly like a downloaded LibriVox file, so the rest of your playback pipeline doesn't care whether audio came from LibriVox or TTS.

**Recommendation**: ship with `AVSpeechSynthesizer` as the always-available fallback, add a cloud TTS provider behind a settings toggle for users who want better quality and don't mind an API key/cost.

---

## 3. Playback Engine

- `AVPlayer` (not `AVAudioPlayer`) if streaming remote URLs directly (LibriVox/archive.org links) — supports buffering, scrubbing, remote assets natively.
- `AVAudioPlayer` if playing fully-downloaded local files (simpler API, good for offline mode).
- Chapter queue: build an `AVQueuePlayer` (subclass of `AVPlayer`) loaded with `AVPlayerItem`s per chapter for gapless chapter-to-chapter playback.
- Speed control: `player.rate` (0.5–3.0x) — persist per-book preference.
- Sleep timer: simple `Timer`/`Task.sleep` that calls `player.pause()`.

### Background audio + lock screen controls
- Enable **Background Modes → Audio, AirPlay, and Picture in Picture** capability in Xcode.
- Set `AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)` — `.spokenAudio` mode specifically tunes EQ/ducking for speech.
- Use `MPNowPlayingInfoCenter.default().nowPlayingInfo` to show title/cover/progress on lock screen.
- Use `MPRemoteCommandCenter.shared()` to hook play/pause/skip/scrub into lock screen & Control Center.

---

## 4. Offline Storage / Persistence

- **SwiftData** (iOS 17+) or Core Data for: library entries, download status, playback position (resume-where-you-left-off), bookmarks, TTS cache metadata.
- Store downloaded/generated audio files in `FileManager.default.urls(for: .documentDirectory, ...)`, not in the database — DB just stores the file path + metadata.
- Track per-book: current chapter, current timestamp (seconds), playback speed, download state (not-downloaded / downloading / downloaded).

---

## 5. Networking

- Plain `URLSession` with `async/await` is enough — no need for Alamofire unless you want its multipart/upload conveniences.
- For downloading large audio files with progress + resumability: `URLSessionDownloadTask` with delegate callbacks for progress, or `Foundation`'s `URLSession.shared.download(from:)` async API for simple cases.

## 6. Recommended Swift Packages (SPM)

| Purpose | Package |
|---|---|
| Cover image loading/caching | Kingfisher (or Nuke) |
| JSON decoding | Native `Codable` (no package needed) |
| Networking sugar (optional) | Alamofire — optional, URLSession is sufficient |
| Waveform/scrubber UI (optional) | `DSWaveformImage` |

---

## 7. Suggested Build Order (for Antigravity to execute as tasks)

1. Models: `Book`, `Chapter`, `PlaybackState` (Codable + SwiftData).
2. Networking layer: Open Library search, LibriVox catalog fetch, archive.org metadata fetch, Gutendex text fetch — each as a small async function returning decoded structs.
3. Local cache manager: download-to-disk + resolve "do we already have audio for this chapter" (narrated or TTS-generated) before hitting network again.
4. TTS service wrapping `AVSpeechSynthesizer.write(...)` → writes an `AVAudioFile`, returns local URL.
5. Playback engine wrapping `AVQueuePlayer`, exposing play/pause/seek/rate/skip-chapter, publishing progress via Combine/`@Published` for the existing UI to bind to.
6. Now Playing / remote command integration for lock screen.
7. Wire the existing UI's search screen to the networking layer, and the existing UI's player screen to the playback engine's published state.

---

## Legal note
Anything sourced from LibriVox/Gutenberg/archive.org is public domain — safe to redistribute and play. Do not attempt to source or stream copyrighted commercial audiobooks (Audible, etc.) without a licensing agreement; there is no legitimate free API for that.
