import SwiftUI

struct AboutView: View {
    @State private var isTrusted = AccessibilityChecker.isTrusted

    var body: some View {
        VStack(spacing: 12) {
            Text("SmoothScroll v1.0.0")
                .font(.headline)

            HStack {
                Text("Accessibility:")
                if isTrusted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Granted")
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Not Granted")
                }
            }

            if !isTrusted {
                Button("Grant Access") {
                    AccessibilityChecker.promptIfNeeded()
                    // Re-check after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        isTrusted = AccessibilityChecker.isTrusted
                    }
                }
            }

            Divider()

            Text("App icon by [Freepik](https://www.freepik.com)")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()

            Button("Quit SmoothScroll") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .onAppear {
            isTrusted = AccessibilityChecker.isTrusted
        }
    }
}
