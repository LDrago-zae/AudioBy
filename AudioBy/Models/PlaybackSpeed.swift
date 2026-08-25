import Foundation

/// Supported playback speeds for audiobooks.
public enum PlaybackSpeed: Float, CaseIterable, Identifiable, Codable, Sendable {
    case half = 0.5
    case threeQuarters = 0.75
    case normal = 1.0
    case oneAndQuarter = 1.25
    case oneAndHalf = 1.5
    case oneAndThreeQuarters = 1.75
    case double = 2.0
    case twoAndHalf = 2.5

    public var id: Float { rawValue }

    public var title: String {
        if rawValue == 1.0 {
            return "1.0× (Normal)"
        }
        if rawValue.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f.0×", rawValue)
        }
        return String(format: "%.2g×", rawValue)
    }

    public var shortTitle: String {
        if rawValue.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f×", rawValue)
        }
        return String(format: "%.2g×", rawValue)
    }
}
