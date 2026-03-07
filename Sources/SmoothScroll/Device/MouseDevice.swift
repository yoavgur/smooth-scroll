import IOKit.hid

struct MouseDevice: Identifiable, Equatable, @unchecked Sendable {
    let vendorID: Int
    let productID: Int
    let name: String
    let hidDevice: IOHIDDevice

    /// Composite key for profile lookup: "vendorID:productID"
    var deviceKey: String { "\(vendorID):\(productID)" }

    var id: String { deviceKey }

    static func == (lhs: MouseDevice, rhs: MouseDevice) -> Bool {
        lhs.deviceKey == rhs.deviceKey
    }
}
