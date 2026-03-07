import AppKit
import SwiftUI

@MainActor
class StatusBarController {
    private var statusItem: NSStatusItem
    private var popover: NSPopover

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: SettingsView())

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "computermouse",
                accessibilityDescription: "SmoothScroll"
            )
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            popover.performClose(sender)
        } else if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
