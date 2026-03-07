import AppKit
import ApplicationServices

enum AccessibilityChecker {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Prompts the user to grant accessibility access if not already granted.
    static func promptIfNeeded() {
        if !isTrusted {
            // Use the raw string key to avoid Swift 6 concurrency warning on the global
            let key = "AXTrustedCheckOptionPrompt" as CFString
            let options = [key: true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }
    }
}
