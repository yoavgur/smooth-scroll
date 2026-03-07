import AppKit

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Check accessibility permissions
        AccessibilityChecker.promptIfNeeded()

        // 2. Start device detection
        DeviceManager.shared.start()

        // 3. Start scroll event interception
        ScrollInterceptor.shared.start()

        // 4. Set up menu bar
        statusBarController = StatusBarController()

        print("[SmoothScroll] Started")
    }

    func applicationWillTerminate(_ notification: Notification) {
        ScrollInterceptor.shared.stop()
        ScrollPoster.shared.stop()
        DeviceManager.shared.stop()
    }
}
