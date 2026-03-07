import Foundation

private let deadZone: Double = 0.1

final class ScrollSmoother: @unchecked Sendable {
    static let shared = ScrollSmoother()

    private let lock = NSLock()
    private var remainingX: Double = 0
    private var remainingY: Double = 0
    private var decayRate: Double = 0.12
    private let referenceInterval: Double = 1.0 / 60.0

    // Track whether a boost is still eligible for the current scroll gesture.
    // Reset when animation finishes (remaining hits zero).
    private var pendingBoostY: Bool = true
    private var pendingBoostX: Bool = true

    // Curve selection and linear-mode state
    private var curve: ScrollCurve = .exponential
    private var linearRateX: Double = 0
    private var linearRateY: Double = 0
    private var animDuration: Double = 0.2

    var isActive: Bool {
        lock.lock()
        defer { lock.unlock() }
        return abs(remainingX) > deadZone || abs(remainingY) > deadZone
    }

    /// Called by ScrollInterceptor when a scroll event arrives.
    func addImpulse(deltaX: Double, deltaY: Double, duration: Double,
                    curve: ScrollCurve = .exponential,
                    minImpulse: Double = 30.0, notchThreshold: Double = 2.0) {
        lock.lock()

        self.curve = curve
        self.animDuration = duration

        // Map duration to decay rate (used by exponential & ease-out curves)
        let k: Double = 3.0
        decayRate = 1.0 - exp(-k * referenceInterval / duration)

        // Same direction: accumulate. Direction reversal: reset.
        if deltaY * remainingY >= 0 {
            remainingY += deltaY
        } else {
            remainingY = deltaY
            pendingBoostY = true
        }

        if deltaX * remainingX >= 0 {
            remainingX += deltaX
        } else {
            remainingX = deltaX
            pendingBoostX = true
        }

        // Boost once accumulated delta exceeds a notch threshold.
        // This filters out sub-notch micro-movements that shouldn't
        // trigger a full notch scroll, while still boosting real notches.
        if pendingBoostY, minImpulse > 0,
            abs(remainingY) >= notchThreshold, abs(remainingY) < minImpulse
        {
            remainingY = copysign(minImpulse, remainingY)
            pendingBoostY = false
        }
        if pendingBoostX, minImpulse > 0,
            abs(remainingX) >= notchThreshold, abs(remainingX) < minImpulse
        {
            remainingX = copysign(minImpulse, remainingX)
            pendingBoostX = false
        }

        // For linear mode: recompute constant emission rate after accumulation
        if curve == .linear {
            linearRateX = remainingX / duration
            linearRateY = remainingY / duration
        }

        lock.unlock()

        // Call AFTER releasing smoother lock to prevent ABBA deadlock with poster lock.
        ScrollPoster.shared.ensureRunning()
    }

    /// Called by ScrollPoster every display frame. Returns nil when animation is done.
    func nextFrame(dt: Double) -> (dx: Double, dy: Double)? {
        lock.lock()
        defer { lock.unlock() }

        guard abs(remainingX) > deadZone || abs(remainingY) > deadZone else {
            remainingX = 0
            remainingY = 0
            pendingBoostY = true
            pendingBoostX = true
            return nil
        }

        let prevX = remainingX
        let prevY = remainingY

        switch curve {
        case .exponential:
            // Pure exponential decay: fast start, long gradual tail
            let factor = pow(1.0 - decayRate, dt / referenceInterval)
            remainingX *= factor
            remainingY *= factor

        case .easeOut:
            // Quadratic ease-out approximation: decelerating feel.
            // Each frame emits a fraction that grows as remaining shrinks,
            // producing a smooth deceleration without needing elapsed-time tracking.
            let baseFraction = dt / animDuration
            // Scale fraction up as remaining shrinks relative to original impulse
            // This creates deceleration: large output early, tapering off
            let factor = min(1.0, baseFraction * 2.5)
            remainingX -= remainingX * factor
            remainingY -= remainingY * factor

        case .linear:
            // Constant emission rate: same speed throughout the animation
            let outX = linearRateX * dt
            let outY = linearRateY * dt
            if abs(outX) >= abs(remainingX) {
                remainingX = 0
            } else {
                remainingX -= outX
            }
            if abs(outY) >= abs(remainingY) {
                remainingY = 0
            } else {
                remainingY -= outY
            }
        }

        // Snap to zero if below dead zone
        if abs(remainingX) < deadZone { remainingX = 0 }
        if abs(remainingY) < deadZone { remainingY = 0 }

        var dx = prevX - remainingX
        var dy = prevY - remainingY

        // Ensure minimum per-frame step so sub-pixel deltas don't get ignored by apps.
        // Clamp to abs(prev) to prevent overshooting remaining and flipping sign.
        let minStep: Double = 0.5
        if abs(dy) > 0.01 && abs(dy) < minStep {
            dy = copysign(min(minStep, abs(prevY)), dy)
            remainingY = prevY - dy
            if abs(remainingY) < deadZone { remainingY = 0 }
        }
        if abs(dx) > 0.01 && abs(dx) < minStep {
            dx = copysign(min(minStep, abs(prevX)), dx)
            remainingX = prevX - dx
            if abs(remainingX) < deadZone { remainingX = 0 }
        }

        return (dx: dx, dy: dy)
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        remainingX = 0
        remainingY = 0
        pendingBoostY = true
        pendingBoostX = true
        linearRateX = 0
        linearRateY = 0
    }
}
