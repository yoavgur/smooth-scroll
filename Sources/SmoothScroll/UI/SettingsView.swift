import SwiftUI

struct SettingsView: View {
    @ObservedObject var profileManager = ProfileManager.shared
    @ObservedObject var deviceManager = DeviceManager.shared
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "computermouse")
                    .font(.title2)
                Text("SmoothScroll")
                    .font(.headline)
                Spacer()
            }
            .padding()

            Divider()

            Picker("", selection: $selectedTab) {
                Text("Devices").tag(0)
                Text("Defaults").tag(1)
                Text("About").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            switch selectedTab {
            case 0:
                DeviceListView()
            case 1:
                ProfileEditorView(
                    profile: Binding(
                        get: { profileManager.defaultProfile },
                        set: { profileManager.updateDefault($0) }
                    ),
                    title: "Default Profile"
                )
                .padding()
            case 2:
                AboutView()
            default:
                EmptyView()
            }

            Spacer(minLength: 0)
        }
        .frame(width: 340, height: 400)
    }
}
