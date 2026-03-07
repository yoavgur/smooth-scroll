import Foundation
import IOKit
import IOKit.hid

/// Timestamp of last HID scroll event from an external mouse.
/// Trackpads don't generate HID wheel events — they use multitouch —
/// so this only fires for actual mice. Used by ScrollInterceptor to
/// distinguish mouse scroll from trackpad scroll.
nonisolated(unsafe) var lastMouseScrollTime: CFAbsoluteTime = 0
nonisolated(unsafe) var lastMouseScrollDeviceKey: String = ""

@MainActor
final class DeviceManager: ObservableObject {
    static let shared = DeviceManager()

    private var hidManager: IOHIDManager?
    @Published private(set) var connectedMice: [MouseDevice] = []

    func start() {
        hidManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        guard let hidManager else { return }

        // Match pointing devices (mice, trackballs)
        let matchingDict: [String: Any] = [
            kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey as String: kHIDUsage_GD_Mouse,
        ]

        IOHIDManagerSetDeviceMatching(hidManager, matchingDict as CFDictionary)

        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(hidManager, deviceConnected, context)
        IOHIDManagerRegisterDeviceRemovalCallback(hidManager, deviceDisconnected, context)

        // Track which device generates scroll events (fires only for mouse HID wheel events,
        // NOT for trackpad multitouch-generated scroll)
        IOHIDManagerRegisterInputValueCallback(hidManager, hidScrollValueCallback, nil)

        IOHIDManagerScheduleWithRunLoop(
            hidManager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue
        )
        IOHIDManagerOpen(hidManager, IOOptionBits(kIOHIDOptionsTypeNone))
    }

    func stop() {
        guard let hidManager else { return }
        IOHIDManagerClose(hidManager, IOOptionBits(kIOHIDOptionsTypeNone))
        self.hidManager = nil
    }

    nonisolated fileprivate func addDevice(_ device: IOHIDDevice) {
        let vendorID =
            IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? Int ?? 0
        let productID =
            IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? Int ?? 0
        let name =
            IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String
            ?? "Unknown Mouse"

        let mouse = MouseDevice(
            vendorID: vendorID,
            productID: productID,
            name: name,
            hidDevice: device
        )

        let deviceKey = mouse.deviceKey
        let deviceName = mouse.name

        Task { @MainActor in
            if !self.connectedMice.contains(where: { $0.deviceKey == deviceKey }) {
                self.connectedMice.append(mouse)
            }
            ProfileManager.shared.activeDeviceKey = deviceKey
            ProfileManager.shared.ensureProfile(for: mouse)
            print("[SmoothScroll] Mouse connected: \(deviceName) (\(deviceKey))")
        }
    }

    nonisolated fileprivate func removeDevice(_ device: IOHIDDevice) {
        let vendorID =
            IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? Int ?? 0
        let productID =
            IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? Int ?? 0
        let deviceKey = "\(vendorID):\(productID)"

        Task { @MainActor in
            self.connectedMice.removeAll { $0.deviceKey == deviceKey }
            if ProfileManager.shared.activeDeviceKey == deviceKey {
                ProfileManager.shared.activeDeviceKey = self.connectedMice.first?.deviceKey
            }
        }
    }
}

// MARK: - HID scroll value callback (identifies which device is scrolling)

private let hidScrollValueCallback: IOHIDValueCallback = { context, result, sender, value in
    let element = IOHIDValueGetElement(value)
    let usagePage = IOHIDElementGetUsagePage(element)
    let usage = IOHIDElementGetUsage(element)

    // Only care about scroll wheel HID values:
    // Vertical: GenericDesktop page (0x01), Wheel usage (0x38)
    // Horizontal: Consumer page (0x0C), AC Pan usage (0x238)
    let isVerticalScroll = usagePage == 0x01 && usage == 0x38
    let isHorizontalScroll = usagePage == 0x0C && usage == 0x238

    guard isVerticalScroll || isHorizontalScroll else { return }

    let device = IOHIDElementGetDevice(element)
    let vendorID = IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? Int ?? 0
    let productID = IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? Int ?? 0

    lastMouseScrollDeviceKey = "\(vendorID):\(productID)"
    lastMouseScrollTime = CFAbsoluteTimeGetCurrent()
}

// MARK: - Device connect/disconnect callbacks

private func deviceConnected(
    context: UnsafeMutableRawPointer?,
    result: IOReturn,
    sender: UnsafeMutableRawPointer?,
    device: IOHIDDevice
) {
    guard let context else { return }
    let manager = Unmanaged<DeviceManager>.fromOpaque(context).takeUnretainedValue()
    manager.addDevice(device)
}

private func deviceDisconnected(
    context: UnsafeMutableRawPointer?,
    result: IOReturn,
    sender: UnsafeMutableRawPointer?,
    device: IOHIDDevice
) {
    guard let context else { return }
    let manager = Unmanaged<DeviceManager>.fromOpaque(context).takeUnretainedValue()
    manager.removeDevice(device)
}
