import Foundation

final class ProfileManager: ObservableObject, @unchecked Sendable {
    static let shared = ProfileManager()

    private let defaults = UserDefaults.standard
    private let profilesKey = "deviceProfiles"
    private let defaultProfileKey = "defaultProfile"

    @Published var profiles: [String: ScrollProfile] = [:]
    @Published var defaultProfile: ScrollProfile = .default

    /// Set by DeviceManager when devices connect/disconnect
    @Published var activeDeviceKey: String?

    /// The active profile based on the current device key.
    /// Called from CGEventTap callback — must be fast and thread-safe enough for a struct read.
    var activeProfile: ScrollProfile {
        if let key = activeDeviceKey,
            let profile = profiles[key], profile.isEnabled
        {
            return profile
        }
        return defaultProfile
    }

    init() {
        load()
    }

    func ensureProfile(for device: MouseDevice) {
        if profiles[device.deviceKey] == nil {
            profiles[device.deviceKey] = ScrollProfile(name: device.name)
            save()
        }
    }

    func updateProfile(for deviceKey: String, _ profile: ScrollProfile) {
        profiles[deviceKey] = profile
        save()
    }

    func updateDefault(_ profile: ScrollProfile) {
        defaultProfile = profile
        save()
    }

    private func load() {
        if let data = defaults.data(forKey: profilesKey),
            let decoded = try? JSONDecoder().decode([String: ScrollProfile].self, from: data)
        {
            profiles = decoded
        }
        if let data = defaults.data(forKey: defaultProfileKey),
            let decoded = try? JSONDecoder().decode(ScrollProfile.self, from: data)
        {
            defaultProfile = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(profiles) {
            defaults.set(data, forKey: profilesKey)
        }
        if let data = try? JSONEncoder().encode(defaultProfile) {
            defaults.set(data, forKey: defaultProfileKey)
        }
    }
}
