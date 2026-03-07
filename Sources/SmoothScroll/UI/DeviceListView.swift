import SwiftUI

struct DeviceListView: View {
    @ObservedObject var deviceManager = DeviceManager.shared
    @ObservedObject var profileManager = ProfileManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                if deviceManager.connectedMice.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "computermouse")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No external mice detected")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    ForEach(deviceManager.connectedMice) { device in
                        DeviceRow(device: device)
                    }
                }
            }
            .padding()
        }
    }
}

struct DeviceRow: View {
    let device: MouseDevice
    @ObservedObject var profileManager = ProfileManager.shared
    @State private var isExpanded = false

    private var profile: Binding<ScrollProfile> {
        Binding(
            get: { profileManager.profiles[device.deviceKey] ?? .default },
            set: { profileManager.updateProfile(for: device.deviceKey, $0) }
        )
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ProfileEditorView(profile: profile, title: device.name)
        } label: {
            HStack {
                Image(systemName: "computermouse")
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.body)
                    Text(device.deviceKey)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
