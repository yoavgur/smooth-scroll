# SmoothScroll

A lightweight macOS menu bar app that adds smooth scrolling to external mice. Built as a native Swift alternative to [Mos](https://mos.caldis.me/).

## Features

- **Smooth scrolling** — transforms clicky mouse wheel steps into fluid, interpolated scroll with configurable curves (linear, ease-out, exponential)
- **Per-device profiles** — automatically detects connected mice via IOHIDManager and lets you configure each one independently
- **Minimum notch distance** — ensures each scroll notch produces a visible, consistent movement (great for high-resolution wheels like the MX Master 3S)
- **Zoom with modifier + horizontal scroll** — hold a modifier key (e.g. Cmd) and use your horizontal scroll wheel to zoom in/out in any app, with configurable sensitivity
- **Reverse scroll** — independently reverse vertical and/or horizontal scroll direction
- **Menu bar UI** — all settings accessible from a clean SwiftUI popover in the menu bar
- **Login item** — optionally starts at login via LaunchAgent

## Requirements

- macOS 13 (Ventura) or later
- Accessibility permission (the app will prompt you on first launch)
- Xcode Command Line Tools (`xcode-select --install`)

## Installation

```bash
# Clone and build
git clone https://github.com/YOUR_USERNAME/SmoothScroll.git
cd SmoothScroll
make install
```

This builds the app, copies it to `/Applications`, and creates a LaunchAgent so it starts at login.

To uninstall:

```bash
make uninstall
```

## Usage

1. Launch SmoothScroll — it appears as a scroll icon in the menu bar
2. Click the menu bar icon to open the settings popover
3. Configure the **Default** profile or select a specific connected mouse
4. Adjust speed, smoothness, curve, and other settings to your liking
5. Grant Accessibility permission when prompted (required for scroll interception)

### Zoom feature

To enable zoom via the horizontal scroll wheel:

1. Toggle **"Zoom with modifier + horizontal scroll"** on
2. Choose your modifier (Cmd, Ctrl, Option, or Shift)
3. Adjust **Zoom sensitivity** (lower = more sensitive)
4. Hold the modifier and scroll the horizontal wheel to zoom in/out

Zoom sends `Cmd+=` / `Cmd+-` to the app under your cursor, so it works in browsers, editors, and most apps.

## Build targets

| Command | Description |
|---------|-------------|
| `make build` | Compile in release mode |
| `make bundle` | Build + create signed `.app` bundle |
| `make run` | Build + bundle + launch |
| `make install` | Build + bundle + copy to /Applications + create login item |
| `make uninstall` | Remove from /Applications + remove login item |
| `make clean` | Remove build artifacts |

## How it works

1. **CGEventTap** at the HID level intercepts scroll wheel events before they reach apps
2. **IOHIDManager** detects connected mice and identifies which device generated each scroll event
3. Trackpad events (which have non-zero scroll phases) are passed through untouched
4. Mouse wheel events are consumed and fed into **ScrollSmoother**, which applies the configured interpolation curve
5. **ScrollPoster** emits smooth, continuous scroll events at ~120Hz via a `DispatchSourceTimer`
6. For zoom, horizontal scroll delta is accumulated and translated into `Cmd+=` / `Cmd+-` keyboard shortcuts sent to the app under the cursor via `CGEvent.postToPid()`

## Credits

- App icon by [Freepik](https://www.freepik.com)

## License

MIT License. See [LICENSE](LICENSE) for details.
