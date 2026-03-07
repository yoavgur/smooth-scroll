import SwiftUI

struct ProfileEditorView: View {
    @Binding var profile: ScrollProfile
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Enable smooth scrolling", isOn: $profile.isEnabled)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Speed")
                    Spacer()
                    Text(String(format: "%.1fx", profile.speedMultiplier))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $profile.speedMultiplier, in: 0.1...5.0, step: 0.1)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Smoothness")
                    Spacer()
                    Text(String(format: "%.2fs", profile.scrollDuration))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $profile.scrollDuration, in: 0.1...1.0, step: 0.05)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Curve")
                Picker("Curve", selection: $profile.scrollCurve) {
                    ForEach(ScrollCurve.allCases, id: \.self) { curve in
                        Text(curve.rawValue).tag(curve)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Min notch distance")
                    Spacer()
                    Text(String(format: "%.0fpx", profile.minNotchDistance))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $profile.minNotchDistance, in: 0...100, step: 5)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Notch sensitivity")
                    Spacer()
                    Text(String(format: "%.1fpx", profile.notchThreshold))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $profile.notchThreshold, in: 0.5...10.0, step: 0.5)
            }

            Divider()

            Toggle("Reverse vertical scroll", isOn: $profile.reverseVertical)
            Toggle("Reverse horizontal scroll", isOn: $profile.reverseHorizontal)
        }
    }
}
