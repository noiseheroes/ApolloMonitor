# Contributing to Apollo Monitor

Thank you for your interest in contributing! This guide will help you get started.

## Prerequisites

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- Universal Audio Apollo device (for testing)
- UA Console / UA Mixer Engine installed

## Setup

```bash
git clone https://github.com/YOUR_USERNAME/ApolloMonitor.git
cd ApolloMonitor
xcodegen generate
open ApolloMonitor.xcodeproj
```

Select your Development Team in Signing & Capabilities, then Build & Run (⌘R).

## Project Structure

```
Shared/                 # Core logic (shared between app + widget)
├── ApolloTCP.swift     # TCP transport: get/set/subscribe commands
├── ApolloController.swift  # State, enumeration, persistence
├── Models.swift        # UAHost, UADevice, UAOutput
└── NetworkDiscovery.swift  # Bonjour NWBrowser

ApolloMonitor/          # Main app UI
├── AppDelegate.swift   # Menu bar setup
├── MonitorView.swift   # Popover with controls
├── SettingsView.swift  # Settings window
└── AboutView.swift     # About window

ApolloMonitorWidget/    # macOS widget (placeholder)
```

### Key Architecture

- **ApolloTCP** is a generic TCP transport. It sends `get`/`set`/`subscribe` commands and parses JSON responses. It knows nothing about audio concepts.
- **ApolloController** is the `ObservableObject` that manages state. It handles device enumeration, output selection, subscribe wiring, and persistence.
- **NetworkDiscovery** uses `NWBrowser` to discover UA Console instances on the LAN via Bonjour (`_uamixer._tcp`).

### Protocol

The UA Mixer Engine exposes a TCP server on port 4710. Commands are null-terminated strings, responses are JSON:

```
get /devices                              → list devices
get /devices/0                            → device name, online status
subscribe /devices/0/outputs/4/Mute       → push updates on change
set /devices/0/outputs/4/CRMonitorLevel/value/ -24.0  → set value
```

See the [cuefinger](https://github.com/franqulator/cuefinger) project for protocol details.

## How to Contribute

### Reporting Bugs

- Check [Issues](https://github.com/noiseheroes/ApolloMonitor/issues) for existing reports
- Include: macOS version, Apollo model, steps to reproduce

### Submitting Code

1. Create a feature branch: `git checkout -b feature/your-change`
2. Follow existing code style and patterns
3. Test with a real Apollo device if possible
4. Commit clearly: `git commit -m "Add: brief description"`
5. Push and open a PR against `main`

### Regenerating the Xcode Project

After adding or removing files, regenerate:

```bash
xcodegen generate
```

The `project.yml` is the source of truth. Don't edit `ApolloMonitor.xcodeproj` manually.

### Generating App Icons

```bash
swift scripts/generate-icon.swift
```

This generates all required macOS icon sizes from a programmatic design using Core Graphics.

## Code Style

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use `@ObservedObject` for passed objects, `@Published` for state
- Keep TCP-related code in `ApolloTCP.swift`, audio logic in `ApolloController.swift`
- Place new shared models in `Shared/Models.swift`

## Testing

Hardware interaction limits automated testing. Please:

- Test with a real Apollo device when possible
- Verify real-time sync (change volume on hardware, confirm app updates)
- Test remote connections if you have multiple Macs
- Check reconnection behavior (quit UA Console, verify auto-reconnect)

## Questions?

Open an issue with the **question** label.
