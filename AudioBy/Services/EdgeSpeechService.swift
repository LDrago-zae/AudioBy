import Foundation

public enum EdgeSpeechError: Error, LocalizedError {
    case emptyAudio
    case missingToken
    case socket(String)

    public var errorDescription: String? {
        switch self {
        case .emptyAudio: return "The neural voice returned no audio."
        case .missingToken: return "Neural voice is not configured. Set EDGE_SPEECH_TOKEN in Secrets.xcconfig or the scheme environment."
        case .socket(let message): return message
        }
    }
}

/// Same neural read-aloud client as the other app: Microsoft neural voices, MP3, with pitch and rate.
public final class EdgeSpeechService: @unchecked Sendable {
    public static let shared = EdgeSpeechService()

    private let session: URLSession
    private let cacheDirectory: URL

    /// Reads from process environment first, then Info.plist (`$(EDGE_SPEECH_TOKEN)` from xcconfig).
    private var token: String {
        Self.secret(named: "EDGE_SPEECH_TOKEN")
    }

    /// Chrome/Edge build used for Sec-MS-GEC-Version and User-Agent.
    private var chrome: String {
        let value = Self.secret(named: "EDGE_SPEECH_CHROME_VERSION")
        return value.isEmpty ? "143.0.3650.75" : value
    }

    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 40
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = caches.appendingPathComponent("EdgeSpeech", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.cacheDirectory = dir
    }

    private static func secret(named key: String) -> String {
        let env = ProcessInfo.processInfo.environment[key]?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !env.isEmpty { return env }

        let plist = (Bundle.main.object(forInfoDictionaryKey: key) as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if plist.isEmpty || plist.hasPrefix("$(") { return "" }
        return plist
    }

    public static func rate(for speed: Float) -> String {
        let percent = Int((speed - 1) * 100)
        return String(format: "%+d%%", percent)
    }

    public func synthesize(text: String, voice: String, rate: String = "+0%", cacheKey: String) async throws -> URL {
        guard !token.isEmpty else { throw EdgeSpeechError.missingToken }
        let voiceName = voice.contains("Neural") ? voice : "en-US-AriaNeural"
        let file = cacheDirectory.appendingPathComponent("\(cacheKey.replacingOccurrences(of: "/", with: "-")).mp3")
        if FileManager.default.fileExists(atPath: file.path),
           (try? FileManager.default.attributesOfItem(atPath: file.path)[.size] as? Int) ?? 0 > 400 {
            return file
        }
        var audio = Data()
        for chunk in Self.chunks(of: text) {
            audio.append(try await speak(chunk, voice: voiceName, rate: rate, pitch: "+0Hz"))
        }
        guard !audio.isEmpty else { throw EdgeSpeechError.emptyAudio }
        try audio.write(to: file, options: .atomic)
        return file
    }

    private func speak(_ text: String, voice: String, rate: String, pitch: String) async throws -> Data {
        let token = self.token
        guard !token.isEmpty else { throw EdgeSpeechError.missingToken }
        let chrome = self.chrome
        let chromeMajor = chrome.split(separator: ".").first.map(String.init) ?? "143"
        let connection = Self.hex(UInt32.random(in: .min ... .max))
            + Self.hex(UInt32.random(in: .min ... .max))
            + Self.hex(UInt32.random(in: .min ... .max))
            + Self.hex(UInt32.random(in: .min ... .max))
        var components = URLComponents()
        components.scheme = "wss"
        components.host = "speech.platform.bing.com"
        components.port = 443
        components.path = "/consumer/speech/synthesize/readaloud/edge/v1"
        components.queryItems = [
            URLQueryItem(name: "TrustedClientToken", value: token),
            URLQueryItem(name: "ConnectionId", value: connection),
            URLQueryItem(name: "Sec-MS-GEC", value: secMsGec(token: token)),
            URLQueryItem(name: "Sec-MS-GEC-Version", value: "2-\(chrome)")
        ]
        guard let url = components.url else { throw EdgeSpeechError.socket("Could not open the voice service.") }
        var request = URLRequest(url: url)
        request.setValue(
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/\(chromeMajor).0.0.0 Safari/537.36 Edg/\(chromeMajor).0.0.0",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("chrome-extension://jdiccldimpdaibmpdkjnbmckianbfold", forHTTPHeaderField: "Origin")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        let muid = Self.hex(UInt32.random(in: .min ... .max)) + Self.hex(UInt32.random(in: .min ... .max))
            + Self.hex(UInt32.random(in: .min ... .max)) + Self.hex(UInt32.random(in: .min ... .max))
        request.setValue("muid=\(muid);", forHTTPHeaderField: "Cookie")

        let socket = session.webSocketTask(with: request)
        socket.resume()
        let now = Self.edgeDate()
        let requestId = connection
        let config = "X-Timestamp:\(now)\r\nContent-Type:application/json; charset=utf-8\r\nPath:speech.config\r\n\r\n{\"context\":{\"synthesis\":{\"audio\":{\"metadataoptions\":{\"sentenceBoundaryEnabled\":\"false\",\"wordBoundaryEnabled\":\"false\"},\"outputFormat\":\"audio-24khz-48kbitrate-mono-mp3\"}}}}\r\n"
        let ssml = "X-RequestId:\(requestId)\r\nContent-Type:application/ssml+xml\r\nX-Timestamp:\(now)Z\r\nPath:ssml\r\n\r\n\(Self.ssml(text, voice: voice, rate: rate, pitch: pitch))"
        try await socket.send(.string(config))
        try await socket.send(.string(ssml))

        var audio = Data()
        while true {
            let message = try await socket.receive()
            switch message {
            case .string(let text):
                if text.contains("Path:turn.end") {
                    socket.cancel(with: .normalClosure, reason: nil)
                    return audio
                }
            case .data(let bytes):
                guard bytes.count >= 2 else { continue }
                let headerLength = Int(bytes[0]) << 8 | Int(bytes[1])
                guard headerLength + 2 <= bytes.count else { continue }
                let header = String(data: bytes.subdata(in: 2..<(2 + headerLength)), encoding: .utf8) ?? ""
                guard header.contains("Content-Type:audio/mpeg") else { continue }
                audio.append(bytes.subdata(in: (2 + headerLength)..<bytes.count))
            @unknown default:
                continue
            }
        }
    }

    func secMsGec(token: String? = nil, unixSeconds: Double = Date().timeIntervalSince1970) -> String {
        let resolved = token ?? self.token
        var ticks = unixSeconds + 11_644_473_600
        ticks -= ticks.truncatingRemainder(dividingBy: 300)
        let scaled = Int64((ticks * 10_000_000).rounded())
        let material = "\(scaled)\(resolved)"
        return EdgeSpeechDigest.tokenHash(Array(material.utf8))
    }

    private static func chunks(of text: String) -> [String] {
        let cleaned = text.replacingOccurrences(of: "\n", with: " ")
        if cleaned.count <= 2400 { return [cleaned] }
        var parts: [String] = []
        var rest = cleaned[...]
        while !rest.isEmpty {
            if rest.count <= 2400 {
                parts.append(String(rest))
                break
            }
            let window = rest.prefix(2400)
            let split = window.lastIndex(of: ".") ?? window.endIndex
            let end = rest.index(after: split) <= rest.endIndex ? rest.index(split, offsetBy: 0, limitedBy: rest.endIndex) ?? split : split
            let take = rest[rest.startIndex...end]
            let piece = String(take).trimmingCharacters(in: .whitespaces)
            if !piece.isEmpty { parts.append(piece) }
            rest = rest[rest.index(after: end)...]
        }
        return parts.isEmpty ? [String(cleaned.prefix(2400))] : parts
    }

    private static func ssml(_ text: String, voice: String, rate: String, pitch: String) -> String {
        let lang = voice.split(separator: "-").prefix(2).joined(separator: "-")
        let safe = text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        return "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='\(lang)'><voice name='\(voice)'><prosody pitch='\(pitch)' rate='\(rate)'>\(safe)</prosody></voice></speak>"
    }

    private static func edgeDate() -> String {
        let now = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE MMM dd yyyy HH:mm:ss"
        return "\(formatter.string(from: now)) GMT+0000 (Coordinated Universal Time)"
    }

    private static func hex(_ value: UInt32) -> String {
        String(format: "%08x", value)
    }
}

enum EdgeSpeechDigest {
    private static let mask: UInt64 = 0xFFFF_FFFF
    private static let shaState: [UInt64] = [0xFD9FBEA2, 0x91243CE7, 0xBE499094, 0xCD2E1E0A, 0x6C006F49, 0x04BD35AB, 0xFEB0A7E4, 0x03EFFBD2]
    private static let shaInitial: [UInt64] = [0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A, 0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19]
    private static let shaSchedule: [UInt64] = [0xEB24BF9E, 0x1558691F, 0xA0C09EE2, 0x0CFA32BA, 0xA622EE8C, 0xD1DD9491, 0xC0DD25A0, 0xF9E70AB6, 0xF0C31573, 0x7058CE4E, 0x7188E606, 0x00E5AB33, 0xD258B060, 0x72766564]
    private static let round: [UInt64] = [
        0x428A2F98, 0x71374491, 0xB5C0FBCF, 0xE9B5DBA5, 0x3956C25B, 0x59F111F1, 0x923F82A4, 0xAB1C5ED5,
        0xD807AA98, 0x12835B01, 0x243185BE, 0x550C7DC3, 0x72BE5D74, 0x80DEB1FE, 0x9BDC06A7, 0xC19BF174,
        0xE49B69C1, 0xEFBE4786, 0x0FC19DC6, 0x240CA1CC, 0x2DE92C6F, 0x4A7484AA, 0x5CB0A9DC, 0x76F988DA,
        0x983E5152, 0xA831C66D, 0xB00327C8, 0xBF597FC7, 0xC6E00BF3, 0xD5A79147, 0x06CA6351, 0x14292967,
        0x27B70A85, 0x2E1B2138, 0x4D2C6DFC, 0x53380D13, 0x650A7354, 0x766A0ABB, 0x81C2C92E, 0x92722C85,
        0xA2BFE8A1, 0xA81A664B, 0xC24B8B70, 0xC76C51A3, 0xD192E819, 0xD6990624, 0xF40E3585, 0x106AA070,
        0x19A4C116, 0x1E376C08, 0x2748774C, 0x34B0BCB5, 0x391C0CB3, 0x4ED8AA4A, 0x5B9CCA4F, 0x682E6FF3,
        0x748F82EE, 0x78A5636F, 0x84C87814, 0x8CC70208, 0x90BEFFFA, 0xA4506CEB, 0xBEF9A3F7, 0xC67178F2
    ]
    private static let blockAdjust: UInt64 = 0xC9DC06A7
    private static let sigma0Adjust: UInt64 = 0x059C0B80
    private static let sigma1Adjust: UInt64 = 0x000B92C0
    private static let cs64Pairs: [(UInt64, UInt64)] = [
        (0xE82E91B1, 0xB32700D0), (0x44DE24C6, 0x88DFF51D), (0x3BEB65BC, 0x29514038), (0xC89C5933, 0xB328CBDF),
        (0x8D1EC211, 0xD405B4D5), (0x314EF5D5, 0x26E55F3C), (0xE92491B1, 0x607801C6), (0xF0A5B9D5, 0x82B2C1FB),
        (0x06064CF3, 0xFA51A3DA), (0xDA79FA60, 0x207CC464), (0xBED20560, 0x3C3C74F3), (0x89F9C9F8, 0xD2D14B61),
        (0x35FA38C6, 0xBB04A2C1), (0xCB49E3C6, 0xC5626167)
    ]

    static func tokenHash(_ data: [UInt8]) -> String {
        let digest = shaDigest(data)
        let pair = cs64Digest(data, digest)
        let cs: [UInt8] = [
            UInt8(pair.0 & 0xff), UInt8((pair.0 >> 8) & 0xff), UInt8((pair.0 >> 16) & 0xff), UInt8((pair.0 >> 24) & 0xff),
            UInt8(pair.1 & 0xff), UInt8((pair.1 >> 8) & 0xff), UInt8((pair.1 >> 16) & 0xff), UInt8((pair.1 >> 24) & 0xff)
        ]
        return "\(hex(cs))-\(hex(digest))"
    }

    private static func u(_ value: UInt64) -> UInt64 { value & mask }
    private static func rol16(_ value: UInt64) -> UInt64 {
        let value = u(value)
        return u((value << 16) | (value >> 16))
    }
    private static func sigma0(_ value: UInt64) -> UInt64 {
        u((value >> 7) ^ (value << 25) ^ (value >> 18) ^ (value << 14) ^ (value >> 3))
    }
    private static func sigma1(_ value: UInt64) -> UInt64 {
        u((value >> 17) ^ (value << 15) ^ (value >> 19) ^ (value << 13) ^ (value >> 10))
    }

    private static func rounds(_ state: [UInt64], _ words: [UInt64], _ first: Int) -> [UInt64] {
        var a = state[0], b = state[1], c = state[2], d = state[3]
        var e = state[4], f = state[5], g = state[6], h = state[7]
        var constants = round
        if first == 14 {
            constants = Array(round.prefix(14)) + [blockAdjust] + Array(round.dropFirst(15))
        }
        let aligned = min(64, ((first + 7) / 8) * 8)
        if first < aligned {
            for index in first..<aligned {
                let rotE = e &* 0x1_0000_0001
                let rotA = a &* 0x1_0000_0001
                let t1 = h &+ ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) &+ (g ^ (e & (f ^ g))) &+ constants[index] &+ words[index]
                let t2 = ((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) &+ ((a & b) | (c & (a | b)))
                let nextA = u(t1 &+ t2)
                let nextE = u(d &+ t1)
                h = g; g = f; f = e; e = nextE; d = c; c = b; b = a; a = nextA
            }
        }
        var index = aligned
        while index < 64 {
            var rotE = e &* 0x1_0000_0001
            var rotA = a &* 0x1_0000_0001
            var t1 = h &+ ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) &+ (g ^ (e & (f ^ g))) &+ constants[index] &+ words[index]
            d = u(d &+ t1)
            h = u(t1 &+ ((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) &+ ((a & b) | (c & (a | b))))
            rotE = d &* 0x1_0000_0001
            rotA = h &* 0x1_0000_0001
            t1 = g &+ ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) &+ (f ^ (d & (e ^ f))) &+ constants[index + 1] &+ words[index + 1]
            c = u(c &+ t1)
            g = u(t1 &+ ((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) &+ ((h & a) | (b & (h | a))))
            rotE = c &* 0x1_0000_0001
            rotA = g &* 0x1_0000_0001
            t1 = f &+ ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) &+ (e ^ (c & (d ^ e))) &+ constants[index + 2] &+ words[index + 2]
            b = u(b &+ t1)
            f = u(t1 &+ ((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) &+ ((g & h) | (a & (g | h))))
            rotE = b &* 0x1_0000_0001
            rotA = f &* 0x1_0000_0001
            t1 = e &+ ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) &+ (d ^ (b & (c ^ d))) &+ constants[index + 3] &+ words[index + 3]
            a = u(a &+ t1)
            e = u(t1 &+ ((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) &+ ((f & g) | (h & (f | g))))
            rotE = a &* 0x1_0000_0001
            rotA = e &* 0x1_0000_0001
            t1 = d &+ ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) &+ (c ^ (a & (b ^ c))) &+ constants[index + 4] &+ words[index + 4]
            h = u(h &+ t1)
            d = u(t1 &+ ((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) &+ ((e & f) | (g & (e | f))))
            rotE = h &* 0x1_0000_0001
            rotA = d &* 0x1_0000_0001
            t1 = c &+ ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) &+ (b ^ (h & (a ^ b))) &+ constants[index + 5] &+ words[index + 5]
            g = u(g &+ t1)
            c = u(t1 &+ ((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) &+ ((d & e) | (f & (d | e))))
            rotE = g &* 0x1_0000_0001
            rotA = c &* 0x1_0000_0001
            t1 = b &+ ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) &+ (a ^ (g & (h ^ a))) &+ constants[index + 6] &+ words[index + 6]
            f = u(f &+ t1)
            b = u(t1 &+ ((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) &+ ((c & d) | (e & (c | d))))
            rotE = f &* 0x1_0000_0001
            rotA = b &* 0x1_0000_0001
            t1 = a &+ ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) &+ (h ^ (f & (g ^ h))) &+ constants[index + 7] &+ words[index + 7]
            e = u(e &+ t1)
            a = u(t1 &+ ((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) &+ ((b & c) | (d & (b | c))))
            index += 8
        }
        return [a, b, c, d, e, f, g, h]
    }

    private static func expand(_ words: inout [UInt64], _ first: Int) {
        for index in first..<64 {
            let x = words[index - 2]
            let y = words[index - 15]
            let s1 = (x >> 17) ^ (x << 15) ^ (x >> 19) ^ (x << 13) ^ (x >> 10)
            let s0 = (y >> 7) ^ (y << 25) ^ (y >> 18) ^ (y << 14) ^ (y >> 3)
            words.append(u(s1 &+ words[index - 7] &+ s0 &+ words[index - 16]))
        }
    }

    private static func shaInit(_ data: [UInt8]) -> [UInt64] {
        var words = [UInt64](repeating: 0, count: 14)
        words.append(be(Array(data[0..<3])))
        words.append(be(Array(data[3..<7])))
        for index in 16..<30 {
            var value = shaSchedule[index - 16]
            if index - 2 >= 14 {
                value = u(value &+ (index == 16 ? (sigma1(words[index - 2]) ^ sigma1Adjust) : sigma1(words[index - 2])))
            }
            if index - 7 >= 14 { value = u(value &+ words[index - 7]) }
            if index - 15 >= 14 {
                value = u(value &+ (index == 29 ? (sigma0(words[index - 15]) ^ sigma0Adjust) : sigma0(words[index - 15])))
            }
            words.append(u(value))
        }
        words.append(u(sigma1(words[28]) &+ words[23] &+ sigma0(words[15]) &+ words[14] &+ blockAdjust &- round[14]))
        expand(&words, 31)
        let working = rounds(shaState, words, 14)
        return (0..<8).map { u(shaInitial[$0] &+ working[$0]) }
    }

    private static func shaDigest(_ data: [UInt8]) -> [UInt8] {
        let length = 57 + data.count
        var padded = Array(data.dropFirst(7))
        padded.append(0x80)
        let fill = (55 - length) % 64
        let padCount = fill < 0 ? fill + 64 : fill
        padded.append(contentsOf: repeatElement(0, count: padCount))
        let bitLength = length * 8
        for shift in stride(from: 56, through: 0, by: -8) {
            padded.append(UInt8((bitLength >> shift) & 0xff))
        }
        var state = shaInit(data)
        var offset = 0
        while offset < padded.count {
            var words: [UInt64] = []
            for i in 0..<16 {
                words.append(be(Array(padded[(offset + i * 4)..<(offset + i * 4 + 4)])))
            }
            expand(&words, 16)
            let working = rounds(state, words, 0)
            state = (0..<8).map { u(state[$0] &+ working[$0]) }
            offset += 64
        }
        return state.flatMap(beBytes)
    }

    private static func be(_ bytes: [UInt8]) -> UInt64 {
        var value: UInt64 = 0
        for byte in bytes { value = (value << 8) | UInt64(byte) }
        return value
    }

    private static func beBytes(_ word: UInt64) -> [UInt8] {
        [UInt8((word >> 24) & 0xff), UInt8((word >> 16) & 0xff), UInt8((word >> 8) & 0xff), UInt8(word & 0xff)]
    }

    private static func leWords(_ data: [UInt8]) -> [UInt64] {
        var padded = data
        let extra = (4 - data.count % 4) % 4
        padded.append(contentsOf: repeatElement(0, count: extra))
        var words: [UInt64] = []
        var i = 0
        while i < padded.count {
            words.append(UInt64(padded[i]) | (UInt64(padded[i + 1]) << 8) | (UInt64(padded[i + 2]) << 16) | (UInt64(padded[i + 3]) << 24))
            i += 4
        }
        if words.count % 2 != 0 { words.append(0) }
        return words
    }

    private static func cs64Digest(_ data: [UInt8], _ digest: [UInt8]) -> (UInt64, UInt64) {
        var keyA = UInt64(digest[0]) | (UInt64(digest[1]) << 8) | (UInt64(digest[2]) << 16) | (UInt64(digest[3]) << 24)
        var keyB = UInt64(digest[4]) | (UInt64(digest[5]) << 8) | (UInt64(digest[6]) << 16) | (UInt64(digest[7]) << 24)
        keyA = u(keyA | 1)
        keyB = u(keyB | 1)
        let factors = [u(keyA &* 0x82893933), u(keyB &* 0x82893933)]
        var terms: [UInt64] = (0..<cs64Pairs.count).map { u(cs64Pairs[$0].0 &* factors[$0 % 2]) }
        var offsets: [UInt64] = cs64Pairs.map { $0.1 }
        let words = leWords([0] + data)
        for index in words.indices {
            let word = words[index]
            var term = word &* (index % 2 == 0 ? keyA : keyB)
            var offset = rol16(word) &* (index % 2 == 0 ? 0xEF0569FB : 0xC31713DB)
            if index == 0 {
                term = u(term &+ 0xF2F90B1A &* factors[0])
                offset = u(offset &+ 0x0B1A0000)
            }
            terms.append(u(term))
            offsets.append(u(offset))
        }
        var swapAcc: UInt64 = 0, swapLast: UInt64 = 0, state: UInt64 = 0, acc: UInt64 = 0
        var index = 0
        while index < terms.count {
            let x = terms[index]
            let y = terms[index + 1]
            var t = rol16(u(offsets[index] &+ x))
            var q = u(t &* 0x76F50F34)
            swapAcc = u(swapAcc &+ u(rol16(q) &* 0xC3EFEA97 &+ q))
            t = rol16(u(offsets[index + 1] &+ y))
            q = u(t &* 0x1881CE3C)
            swapLast = u(rol16(q) &* 0x35BD1EC9 &+ q)
            swapAcc = u(swapAcc &+ swapLast)
            state = u(state &* keyA &+ x)
            state = u(rol16(state) &* 0xCF98B111)
            state = u(rol16(state) &* 0x87085B9F)
            state = u(rol16(state) &* 0x12CEB96D)
            state = u(rol16(state) &* 0x257E1D83)
            acc = u(acc &+ state)
            t = u(state &* keyB &+ y)
            t = u(rol16(t) &* 0xA27416F5)
            t = u(rol16(t) &* 0xD38396FF)
            state = u(rol16(u(rol16(t) &* 0x7C932B89)) &* 0xBFA49F69)
            acc = u(acc &+ state)
            index += 2
        }
        return (u(swapLast ^ state), u(swapAcc ^ acc))
    }

    private static func hex(_ bytes: [UInt8]) -> String {
        bytes.map { String(format: "%02X", $0) }.joined()
    }
}
