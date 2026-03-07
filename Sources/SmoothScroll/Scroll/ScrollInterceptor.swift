import ApplicationServices
import CoreGraphics
import Foundation

final class ScrollInterceptor: @unchecked Sendable {
    static let shared = ScrollInterceptor()

    private(set) var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func start() {
        let eventMask: CGEventMask = 1 << CGEventType.scrollWheel.rawValue

        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: scrollCallback,
            userInfo: nil
        )

        guard let eventTap else {
            print("[SmoothScroll] FAILED to create event tap. Grant Accessibility permission.")
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        print("[SmoothScroll] Event tap started")
    }

    func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }
}

private func scrollCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {

    // Re-enable tap if system disabled it
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = ScrollInterceptor.shared.eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passUnretained(event)
    }

    guard type == .scrollWheel else {
        return Unmanaged.passUnretained(event)
    }

    // Distinguish trackpad from mouse using scroll phases.
    // Trackpad gestures have non-zero scrollPhase during touch and
    // non-zero momentumPhase during momentum after lift.
    // Mouse wheels (including continuous ones like MX Master) have both at 0.
    let scrollPhase = event.getIntegerValueField(.scrollWheelEventScrollPhase)
    let momentumPhase = event.getIntegerValueField(.scrollWheelEventMomentumPhase)

    if scrollPhase != 0 || momentumPhase != 0 {
        return Unmanaged.passUnretained(event)
    }

    // Mouse scroll event — capture deltas
    let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous)
    let deltaY: Double
    let deltaX: Double
    if isContinuous != 0 {
        deltaY = event.getDoubleValueField(.scrollWheelEventPointDeltaAxis1)
        deltaX = event.getDoubleValueField(.scrollWheelEventPointDeltaAxis2)
    } else {
        deltaY = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
        deltaX = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2)
    }

    if abs(deltaY) > 0.001 || abs(deltaX) > 0.001 {
        let deviceKey = lastMouseScrollDeviceKey
        let profile: ScrollProfile
        if !deviceKey.isEmpty,
            let deviceProfile = ProfileManager.shared.profiles[deviceKey],
            deviceProfile.isEnabled
        {
            profile = deviceProfile
        } else {
            profile = ProfileManager.shared.defaultProfile
        }

        guard profile.isEnabled else {
            return Unmanaged.passUnretained(event)
        }

        let speedX = deltaX * profile.speedMultiplier * (profile.reverseHorizontal ? -1.0 : 1.0)
        let speedY = deltaY * profile.speedMultiplier * (profile.reverseVertical ? -1.0 : 1.0)
        ScrollSmoother.shared.addImpulse(
            deltaX: speedX,
            deltaY: speedY,
            duration: profile.scrollDuration,
            curve: profile.scrollCurve,
            minImpulse: profile.minNotchDistance,
            notchThreshold: profile.notchThreshold
        )
    }

    return nil
}
