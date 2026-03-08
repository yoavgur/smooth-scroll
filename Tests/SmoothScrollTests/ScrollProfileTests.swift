import Testing
import Foundation
@testable import SmoothScroll

// MARK: - Default Values

@Suite("ScrollProfile – Defaults")
struct DefaultValuesTests {

    @Test("Static .default has expected field values")
    func staticDefault() {
        let p = ScrollProfile.default
        #expect(p.name == "Default")
        #expect(p.isEnabled == true)
        #expect(p.speedMultiplier == 1.0)
        #expect(p.scrollDuration == 0.2)
        #expect(p.scrollCurve == .exponential)
        #expect(p.minNotchDistance == 30.0)
        #expect(p.notchThreshold == 2.0)
        #expect(p.reverseVertical == false)
        #expect(p.reverseHorizontal == false)
    }

    @Test("Init with only name uses default values")
    func initWithName() {
        let p = ScrollProfile(name: "Test Mouse")
        #expect(p.name == "Test Mouse")
        #expect(p.isEnabled == true)
        #expect(p.speedMultiplier == 1.0)
        #expect(p.scrollCurve == .exponential)
    }
}

// MARK: - Codable Round-Trip

@Suite("ScrollProfile – Codable")
struct CodableTests {

    @Test("Encode and decode preserves all fields")
    func roundTrip() throws {
        var original = ScrollProfile(name: "MX Master 3S")
        original.isEnabled = false
        original.speedMultiplier = 2.5
        original.scrollDuration = 0.5
        original.scrollCurve = .easeOut
        original.minNotchDistance = 50.0
        original.notchThreshold = 5.0
        original.reverseVertical = true
        original.reverseHorizontal = true

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ScrollProfile.self, from: data)

        #expect(decoded == original)
    }

    @Test("Decode with only 'name' field uses defaults for everything else")
    func minimalJSON() throws {
        let json = """
        {"name": "Minimal"}
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(ScrollProfile.self, from: data)

        #expect(decoded.name == "Minimal")
        #expect(decoded.isEnabled == true)
        #expect(decoded.speedMultiplier == 1.0)
        #expect(decoded.scrollDuration == 0.2)
        #expect(decoded.scrollCurve == .exponential)
        #expect(decoded.minNotchDistance == 30.0)
        #expect(decoded.notchThreshold == 2.0)
        #expect(decoded.reverseVertical == false)
        #expect(decoded.reverseHorizontal == false)
    }

    @Test("Decode tolerates extra unknown fields")
    func extraFields() throws {
        let json = """
        {"name": "Future", "unknownField": 42, "anotherNew": "hello"}
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(ScrollProfile.self, from: data)
        #expect(decoded.name == "Future")
    }

    @Test("Dictionary of profiles round-trips (simulates ProfileManager storage)")
    func dictionaryRoundTrip() throws {
        var profiles: [String: ScrollProfile] = [:]
        profiles["1133:16505"] = ScrollProfile(name: "MX Master 3S")

        var custom = ScrollProfile(name: "G502")
        custom.speedMultiplier = 3.0
        custom.scrollCurve = .linear
        profiles["1133:16900"] = custom

        let data = try JSONEncoder().encode(profiles)
        let decoded = try JSONDecoder().decode([String: ScrollProfile].self, from: data)

        #expect(decoded.count == 2)
        #expect(decoded["1133:16505"]?.name == "MX Master 3S")
        #expect(decoded["1133:16900"]?.speedMultiplier == 3.0)
        #expect(decoded["1133:16900"]?.scrollCurve == .linear)
    }
}

// MARK: - ScrollCurve Enum

@Suite("ScrollCurve")
struct ScrollCurveTests {

    @Test("Raw values match display strings")
    func rawValues() {
        #expect(ScrollCurve.linear.rawValue == "Linear")
        #expect(ScrollCurve.easeOut.rawValue == "Ease Out")
        #expect(ScrollCurve.exponential.rawValue == "Exponential")
    }

    @Test("CaseIterable contains all three curves")
    func allCases() {
        #expect(ScrollCurve.allCases.count == 3)
        #expect(ScrollCurve.allCases.contains(.linear))
        #expect(ScrollCurve.allCases.contains(.easeOut))
        #expect(ScrollCurve.allCases.contains(.exponential))
    }

    @Test("Codable round-trip for each curve")
    func codableRoundTrip() throws {
        for curve in ScrollCurve.allCases {
            let data = try JSONEncoder().encode(curve)
            let decoded = try JSONDecoder().decode(ScrollCurve.self, from: data)
            #expect(decoded == curve, "Round-trip failed for \(curve)")
        }
    }
}

// MARK: - Equatable

@Suite("ScrollProfile – Equatable")
struct EquatableTests {

    @Test("Identical profiles are equal")
    func identicalAreEqual() {
        let a = ScrollProfile(name: "Test")
        let b = ScrollProfile(name: "Test")
        #expect(a == b)
    }

    @Test("Profiles with different fields are not equal")
    func differentAreNotEqual() {
        let a = ScrollProfile(name: "Test")
        var b = ScrollProfile(name: "Test")
        b.speedMultiplier = 2.0
        #expect(a != b)
    }

    @Test("Different names make profiles not equal")
    func differentNames() {
        let a = ScrollProfile(name: "Mouse A")
        let b = ScrollProfile(name: "Mouse B")
        #expect(a != b)
    }
}
