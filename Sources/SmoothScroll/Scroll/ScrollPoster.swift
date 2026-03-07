import CoreGraphics
import Foundation

final class ScrollPoster: @unchecked Sendable {
    static let shared = ScrollPoster()

    private var timer: DispatchSourceTimer?
    private var lastTime: CFAbsoluteTime = 0
    private var idleFrameCount = 0
    private let maxIdleFrames = 360  // ~3 seconds at 120Hz

    func ensureRunning() {
        idleFrameCount = 0

        if timer != nil { return }

        lastTime = CFAbsoluteTimeGetCurrent()

        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now(), repeating: .microseconds(8333))  // ~120Hz
        t.setEventHandler { [weak self] in
            self?.frameCallback()
        }
        t.resume()
        timer = t
        // print("[SmoothScroll] Timer started")
    }

    func stop() {
        timer?.cancel()
        timer = nil
        lastTime = 0
        idleFrameCount = 0
        print("[SmoothScroll] Timer stopped")
    }

    private func frameCallback() {
        let now = CFAbsoluteTimeGetCurrent()
        let dt = lastTime == 0 ? (1.0 / 120.0) : (now - lastTime)
        lastTime = now

        // Clamp dt to avoid huge jumps if timer stalls
        let clampedDt = min(dt, 0.05)

        guard let (dx, dy) = ScrollSmoother.shared.nextFrame(dt: clampedDt) else {
            idleFrameCount += 1
            if idleFrameCount > maxIdleFrames {
                stop()
            }
            return
        }

        idleFrameCount = 0
        postScrollEvent(deltaX: dx, deltaY: dy)
    }

    private func postScrollEvent(deltaX: Double, deltaY: Double) {
        guard let event = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 2,
            wheel1: Int32(round(deltaY)),
            wheel2: Int32(round(deltaX)),
            wheel3: 0
        ) else { return }

        event.setIntegerValueField(CGEventField.scrollWheelEventIsContinuous, value: 1)

        event.setDoubleValueField(CGEventField.scrollWheelEventFixedPtDeltaAxis1, value: deltaY)
        event.setDoubleValueField(CGEventField.scrollWheelEventPointDeltaAxis1, value: deltaY)
        event.setDoubleValueField(CGEventField.scrollWheelEventFixedPtDeltaAxis2, value: deltaX)
        event.setDoubleValueField(CGEventField.scrollWheelEventPointDeltaAxis2, value: deltaX)

        event.post(tap: CGEventTapLocation.cgSessionEventTap)
    }
}
