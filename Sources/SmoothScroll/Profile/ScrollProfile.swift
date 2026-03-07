import Foundation

/// Interpolation curve for smooth scrolling animation.
enum ScrollCurve: String, Codable, CaseIterable, Equatable {
    case linear = "Linear"
    case easeOut = "Ease Out"
    case exponential = "Exponential"
}

struct ScrollProfile: Equatable {
    var name: String
    var isEnabled: Bool = true

    /// Speed multiplier on raw deltas (0.1 = very slow, 5.0 = very fast)
    var speedMultiplier: Double = 1.0

    /// Duration of smooth scroll animation in seconds (0.1 = snappy, 1.0 = long coast)
    var scrollDuration: Double = 0.2

    /// Interpolation curve: linear (constant speed), ease-out (decelerate), exponential (fast start, long tail)
    var scrollCurve: ScrollCurve = .exponential

    /// Minimum pixels per scroll notch when starting from rest (0 = no boost, 100 = strong)
    var minNotchDistance: Double = 30.0

    /// Minimum accumulated delta (px) before boost triggers (filters sub-notch micro-movements)
    var notchThreshold: Double = 2.0

    var reverseVertical: Bool = false
    var reverseHorizontal: Bool = false

    static let `default` = ScrollProfile(name: "Default")
}

extension ScrollProfile: Codable {
    enum CodingKeys: String, CodingKey {
        case name, isEnabled, speedMultiplier, scrollDuration, scrollCurve, minNotchDistance, notchThreshold
        case reverseVertical, reverseHorizontal
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        isEnabled = try c.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        speedMultiplier = try c.decodeIfPresent(Double.self, forKey: .speedMultiplier) ?? 1.0
        scrollDuration = try c.decodeIfPresent(Double.self, forKey: .scrollDuration) ?? 0.2
        scrollCurve = try c.decodeIfPresent(ScrollCurve.self, forKey: .scrollCurve) ?? .exponential
        minNotchDistance = try c.decodeIfPresent(Double.self, forKey: .minNotchDistance) ?? 30.0
        notchThreshold = try c.decodeIfPresent(Double.self, forKey: .notchThreshold) ?? 2.0
        reverseVertical = try c.decodeIfPresent(Bool.self, forKey: .reverseVertical) ?? false
        reverseHorizontal = try c.decodeIfPresent(Bool.self, forKey: .reverseHorizontal) ?? false
    }
}
