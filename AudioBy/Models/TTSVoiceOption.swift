import Foundation
import AVFoundation

/// Represents a selectable native iOS AVSpeechSynthesis voice option.
public struct TTSVoiceOption: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let language: String
    public let regionName: String
    public let qualityDescription: String
    public let gender: String
    public let flag: String

    public init(
        id: String,
        name: String,
        language: String,
        regionName: String,
        qualityDescription: String,
        gender: String,
        flag: String
    ) {
        self.id = id
        self.name = name
        self.language = language
        self.regionName = regionName
        self.qualityDescription = qualityDescription
        self.gender = gender
        self.flag = flag
    }

    public static func from(voice: AVSpeechSynthesisVoice) -> TTSVoiceOption {
        let name = voice.name
        let lang = voice.language
        var region = "Global"
        var flag = "🌐"

        if lang.starts(with: "en-US") {
            region = "United States"
            flag = "🇺🇸"
        } else if lang.starts(with: "en-GB") {
            region = "United Kingdom"
            flag = "🇬🇧"
        } else if lang.starts(with: "en-AU") {
            region = "Australia"
            flag = "🇦🇺"
        } else if lang.starts(with: "en-IE") {
            region = "Ireland"
            flag = "🇮🇪"
        } else if lang.starts(with: "en-IN") {
            region = "India"
            flag = "🇮🇳"
        } else if lang.starts(with: "en-ZA") {
            region = "South Africa"
            flag = "🇿🇦"
        } else if lang.starts(with: "fr") {
            region = "France"
            flag = "🇫🇷"
        } else if lang.starts(with: "es") {
            region = "Spain"
            flag = "🇪🇸"
        } else if lang.starts(with: "de") {
            region = "Germany"
            flag = "🇩🇪"
        }

        let quality: String
        switch voice.quality {
        case .enhanced:
            quality = "Enhanced Studio"
        case .premium:
            quality = "Premium Ultra"
        default:
            quality = "Natural"
        }

        let genderStr: String
        switch voice.gender {
        case .female: genderStr = "Female"
        case .male: genderStr = "Male"
        default: genderStr = "Natural"
        }

        return TTSVoiceOption(
            id: voice.identifier,
            name: name,
            language: lang,
            regionName: region,
            qualityDescription: quality,
            gender: genderStr,
            flag: flag
        )
    }
}
