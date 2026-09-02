import Foundation

public struct ElevenLabsVoice: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let style: String
}

public final class ElevenLabsService: @unchecked Sendable {
    public static let shared = ElevenLabsService()

    public let voices: [ElevenLabsVoice] = [
        ElevenLabsVoice(id: "21m00Tcm4TlvDq8ikWAM", name: "Rachel", style: "Calm narrative"),
        ElevenLabsVoice(id: "EXAVITQu4vr4xnSDxMaL", name: "Bella", style: "Soft studio"),
        ElevenLabsVoice(id: "ErXwobaYiN019PkySvjV", name: "Antoni", style: "Warm male"),
        ElevenLabsVoice(id: "MF3mGyEYCl7XYWbV9V6O", name: "Elli", style: "Bright female"),
        ElevenLabsVoice(id: "TxGEqnHWrfWFTfGW9XjX", name: "Josh", style: "Deep male"),
        ElevenLabsVoice(id: "pNInz6obpgDQGcFmaJgB", name: "Adam", style: "Neutral narration")
    ]

    private let selectedVoiceDefaults = "AudioBy.ElevenLabsVoiceId"
    private let fileManager = FileManager.default

    /// Reads from process environment first, then Info.plist (`$(ELEVENLABS_API_KEY)` from xcconfig).
    public var apiKey: String {
        let env = ProcessInfo.processInfo.environment["ELEVENLABS_API_KEY"]?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !env.isEmpty { return env }

        let plist = (Bundle.main.object(forInfoDictionaryKey: "ELEVENLABS_API_KEY") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if plist.isEmpty || plist.hasPrefix("$(") { return "" }
        return plist
    }

    public var selectedVoiceId: String {
        get { UserDefaults.standard.string(forKey: selectedVoiceDefaults) ?? voices[0].id }
        set { UserDefaults.standard.set(newValue, forKey: selectedVoiceDefaults) }
    }

    public var isConfigured: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var cacheDirectory: URL {
        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("ElevenLabs", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    public func cachedURL(bookId: String, chapterId: String, voiceId: String) -> URL? {
        let key = BookCachePaths.cacheKey(bookId: bookId)
        let unified = BookCachePaths.default.studioAudioURL(forKey: key, chapterId: chapterId, voiceId: voiceId)
        if fileManager.fileExists(atPath: unified.path) { return unified }
        let legacy = cacheDirectory.appendingPathComponent("\(bookId)-\(chapterId)-\(voiceId).mp3")
        return fileManager.fileExists(atPath: legacy.path) ? legacy : nil
    }

    public func synthesize(text: String, bookId: String, chapterId: String, voiceId: String) async throws -> URL {
        if let cached = cachedURL(bookId: bookId, chapterId: chapterId, voiceId: voiceId) {
            return cached
        }
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            throw ElevenLabsError.missingAPIKey
        }
        let snippet = String(text.prefix(4800))
        guard let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceId)") else {
            throw ElevenLabsError.badRequest
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(trimmedKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
        let body: [String: Any] = [
            "text": snippet,
            "model_id": "eleven_monolingual_v1",
            "voice_settings": ["stability": 0.4, "similarity_boost": 0.75]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ElevenLabsError.badStatus((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        let key = BookCachePaths.cacheKey(bookId: bookId)
        let audioDir = BookCachePaths.default.audioDirectory(forKey: key)
        try fileManager.createDirectory(at: audioDir, withIntermediateDirectories: true)
        let dest = BookCachePaths.default.studioAudioURL(forKey: key, chapterId: chapterId, voiceId: voiceId)
        try data.write(to: dest, options: .atomic)
        return dest
    }

    public enum ElevenLabsError: LocalizedError {
        case missingAPIKey
        case badRequest
        case badStatus(Int)

        public var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "Studio voices are not configured. Set ELEVENLABS_API_KEY in the environment or Secrets.xcconfig."
            case .badRequest:
                return "Could not start studio narration."
            case .badStatus(let code):
                return "Studio voice request failed (\(code))."
            }
        }
    }
}
