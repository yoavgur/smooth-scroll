import Testing
@testable import SmoothScroll

// MARK: - Helpers

/// Drain all frames from a smoother instance and return the total emitted delta.
private func drainAll(
    _ smoother: ScrollSmoother,
    dt: Double = 1.0 / 120.0,
    maxFrames: Int = 5000
) -> (totalX: Double, totalY: Double) {
    var totalX = 0.0
    var totalY = 0.0
    for _ in 0..<maxFrames {
        guard let (dx, dy) = smoother.nextFrame(dt: dt) else { break }
        totalX += dx
        totalY += dy
    }
    return (totalX, totalY)
}

// MARK: - Exponential Curve

@Suite("ScrollSmoother – Exponential Curve")
struct ExponentialCurveTests {

    @Test("Total output approximately equals input impulse")
    func totalOutputMatchesInput() {
        let s = ScrollSmoother()
        s.addImpulse(deltaX: 0, deltaY: 100, duration: 0.3,
                     curve: .exponential, minImpulse: 0, notchThreshold: 0)

        let (_, totalY) = drainAll(s)
        #expect(abs(totalY - 100) < 1.0,
                "Expected ~100px total, got \(totalY)")
    }

    @Test("Output decays over time — early frames emit more than later frames")
    func outputDecays() {
        let s = ScrollSmoother()
        s.addImpulse(deltaX: 0, deltaY: 200, duration: 0.3,
                     curve: .exponential, minImpulse: 0, notchThreshold: 0)

        let dt = 1.0 / 120.0
        var earlySum = 0.0
        for _ in 0..<10 {
            if let (_, dy) = s.nextFrame(dt: dt) { earlySum += abs(dy) }
        }
        // Skip middle frames
        for _ in 0..<100 { _ = s.nextFrame(dt: dt) }
        var lateSum = 0.0
        for _ in 0..<10 {
            if let (_, dy) = s.nextFrame(dt: dt) { lateSum += abs(dy) }
        }

        #expect(earlySum > lateSum,
                "Early frames (\(earlySum)) should emit more than late frames (\(lateSum))")
    }

    @Test("Horizontal impulse works identically")
    func horizontalImpulse() {
        let s = ScrollSmoother()
        s.addImpulse(deltaX: 80, deltaY: 0, duration: 0.3,
                     curve: .exponential, minImpulse: 0, notchThreshold: 0)

        let (totalX, totalY) = drainAll(s)
        #expect(abs(totalX - 80) < 1.0)
        #expect(abs(totalY) < 0.1)
    }
}

// MARK: - Ease-Out Curve

@Suite("ScrollSmoother – Ease-Out Curve")
struct EaseOutCurveTests {

    @Test("Total output approximately equals input impulse")
    func totalOutputMatchesInput() {
        let s = ScrollSmoother()
        s.addImpulse(deltaX: 0, deltaY: 100, duration: 0.3,
                     curve: .easeOut, minImpulse: 0, notchThreshold: 0)

        let (_, totalY) = drainAll(s)
        #expect(abs(totalY - 100) < 1.0,
                "Expected ~100px total, got \(totalY)")
    }
}

// MARK: - Linear Curve

@Suite("ScrollSmoother – Linear Curve")
struct LinearCurveTests {

    @Test("Total output approximately equals input impulse")
    func totalOutputMatchesInput() {
        let s = ScrollSmoother()
        s.addImpulse(deltaX: 0, deltaY: 100, duration: 0.3,
                     curve: .linear, minImpulse: 0, notchThreshold: 0)

        let (_, totalY) = drainAll(s)
        #expect(abs(totalY - 100) < 1.0,
                "Expected ~100px total, got \(totalY)")
    }

    @Test("Frame output is roughly constant")
    func constantFrameOutput() {
        let s = ScrollSmoother()
        s.addImpulse(deltaX: 0, deltaY: 120, duration: 0.5,
                     curve: .linear, minImpulse: 0, notchThreshold: 0)

        let dt = 1.0 / 120.0
        var outputs: [Double] = []
        for _ in 0..<30 {
            if let (_, dy) = s.nextFrame(dt: dt) { outputs.append(dy) }
        }

        guard let first = outputs.first else {
            Issue.record("No frames produced")
            return
        }
        for (i, value) in outputs.enumerated() {
            #expect(abs(value - first) < 0.5,
                    "Frame \(i) output \(value) differs from first frame \(first)")
        }
    }
}

// MARK: - Dead Zone

@Suite("ScrollSmoother – Dead Zone")
struct DeadZoneTests {

    @Test("Very small impulse completes immediately")
    func smallImpulseSnapsToZero() {
        let s = ScrollSmoother()
        s.addImpulse(deltaX: 0, deltaY: 0.05, duration: 0.3,
                     curve: .exponential, minImpulse: 0, notchThreshold: 0)

        let result = s.nextFrame(dt: 1.0 / 120.0)
        #expect(result == nil, "Impulse below dead zone should complete immediately")
    }

    @Test("isActive is false when idle")
    func isActiveWhenIdle() {
        let s = ScrollSmoother()
        #expect(!s.isActive, "Fresh smoother should not be active")
    }

    @Test("isActive is true after impulse, false after draining")
    func isActiveAfterImpulse() {
        let s = ScrollSmoother()
        s.addImpulse(deltaX: 0, deltaY: 100, duration: 0.2,
                     curve: .exponential, minImpulse: 0, notchThreshold: 0)
        #expect(s.isActive, "Should be active after impulse")

        _ = drainAll(s)
        #expect(!s.isActive, "Should be inactive after draining")
    }
}

// MARK: - Boost Logic

@Suite("ScrollSmoother – Notch Boost")
struct BoostTests {

    @Test("Small delta gets boosted to minImpulse")
    func boostKicksIn() {
        let s = ScrollSmoother()
        s.addImpulse(deltaX: 0, deltaY: 5, duration: 0.3,
                     curve: .exponential, minImpulse: 30, notchThreshold: 2)

        let (_, totalY) = drainAll(s)
        #expect(abs(totalY - 30) < 1.0,
                "Expected boosted output ~30px, got \(totalY)")
    }

    @Test("Delta below notch threshold does NOT get boosted")
    func noBelowThreshold() {
        let s = ScrollSmoother()
        s.addImpulse(deltaX: 0, deltaY: 1, duration: 0.3,
                     curve: .exponential, minImpulse: 30, notchThreshold: 2)

        let (_, totalY) = drainAll(s)
        #expect(totalY < 5,
                "Expected unboosted output ~1px, got \(totalY)")
    }

    @Test("Delta already above minImpulse is not modified")
    func noBoostAboveMin() {
        let s = ScrollSmoother()
        s.addImpulse(deltaX: 0, deltaY: 50, duration: 0.3,
                     curve: .exponential, minImpulse: 30, notchThreshold: 2)

        let (_, totalY) = drainAll(s)
        #expect(abs(totalY - 50) < 1.0,
                "Expected unmodified output ~50px, got \(totalY)")
    }

    @Test("Negative delta gets boosted correctly (preserves sign)")
    func negativeBoost() {
        let s = ScrollSmoother()
        s.addImpulse(deltaX: 0, deltaY: -5, duration: 0.3,
                     curve: .exponential, minImpulse: 30, notchThreshold: 2)

        let (_, totalY) = drainAll(s)
        #expect(abs(totalY - (-30)) < 1.0,
                "Expected boosted negative output ~-30px, got \(totalY)")
    }
}

// MARK: - Direction Reversal

@Suite("ScrollSmoother – Direction & Accumulation")
struct DirectionTests {

    @Test("Same-direction impulses accumulate")
    func sameDirectionAccumulates() {
        let s = ScrollSmoother()
        s.addImpulse(deltaX: 0, deltaY: 50, duration: 0.3,
                     curve: .exponential, minImpulse: 0, notchThreshold: 0)
        s.addImpulse(deltaX: 0, deltaY: 50, duration: 0.3,
                     curve: .exponential, minImpulse: 0, notchThreshold: 0)

        let (_, totalY) = drainAll(s)
        #expect(abs(totalY - 100) < 2.0,
                "Expected ~100px accumulated, got \(totalY)")
    }

    @Test("Direction reversal resets remaining")
    func directionReversalResets() {
        let s = ScrollSmoother()
        s.addImpulse(deltaX: 0, deltaY: 100, duration: 0.3,
                     curve: .exponential, minImpulse: 0, notchThreshold: 0)

        let dt = 1.0 / 120.0
        for _ in 0..<5 { _ = s.nextFrame(dt: dt) }

        s.addImpulse(deltaX: 0, deltaY: -80, duration: 0.3,
                     curve: .exponential, minImpulse: 0, notchThreshold: 0)

        let (_, totalY) = drainAll(s)
        #expect(totalY < 0, "After reversal, output should be negative")
        #expect(abs(totalY - (-80)) < 2.0,
                "Expected ~-80px after reversal, got \(totalY)")
    }
}

// MARK: - Reset

@Suite("ScrollSmoother – Reset")
struct ResetTests {

    @Test("Reset clears all state")
    func resetClearsState() {
        let s = ScrollSmoother()
        s.addImpulse(deltaX: 50, deltaY: 100, duration: 0.3,
                     curve: .exponential, minImpulse: 0, notchThreshold: 0)
        #expect(s.isActive)

        s.reset()
        #expect(!s.isActive, "Should be inactive after reset")

        let result = s.nextFrame(dt: 1.0 / 120.0)
        #expect(result == nil, "Should produce no frames after reset")
    }
}

// MARK: - Combined X and Y

@Suite("ScrollSmoother – Combined Axes")
struct CombinedAxesTests {

    @Test("Simultaneous X and Y impulses both drain correctly")
    func bothAxes() {
        let s = ScrollSmoother()
        s.addImpulse(deltaX: 60, deltaY: 90, duration: 0.3,
                     curve: .exponential, minImpulse: 0, notchThreshold: 0)

        let (totalX, totalY) = drainAll(s)
        #expect(abs(totalX - 60) < 1.0, "X: expected ~60, got \(totalX)")
        #expect(abs(totalY - 90) < 1.0, "Y: expected ~90, got \(totalY)")
    }
}
