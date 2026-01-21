import AppKit
import SwiftUI
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var menu: NSMenu?
    private var apollo: ApolloController?
    private var settingsWindow: NSWindow?
    private var aboutWindow: NSWindow?

    // User preferences
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("selectedOutput") private var selectedOutput = "4"

    func applicationDidFinishLaunching(_ notification: Notification) {
        apollo = ApolloController()

        setupStatusItem()
        setupPopover()
        setupMenu()

        NSApp.setActivationPolicy(.accessory)
    }

    // MARK: - Status Item Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }

        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let image = NSImage(systemSymbolName: "dial.medium.fill", accessibilityDescription: "Apollo Monitor")?
            .withSymbolConfiguration(config)
        image?.isTemplate = true

        button.image = image
        button.target = self
        button.action = #selector(handleClick)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        // Accessibility
        button.setAccessibilityLabel("Apollo Monitor")
        button.setAccessibilityHelp("Click to open volume controls, right-click for menu")
    }

    private func setupPopover() {
        guard let apollo = apollo else { return }

        popover = NSPopover()
        popover?.contentSize = NSSize(width: 280, height: 360)
        popover?.behavior = .transient
        popover?.animates = true
        popover?.contentViewController = NSHostingController(rootView: MonitorView(apollo: apollo))
    }

    private func setupMenu() {
        menu = NSMenu()

        let preferencesItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        preferencesItem.target = self
        menu?.addItem(preferencesItem)

        let aboutItem = NSMenuItem(title: "About Apollo Monitor", action: #selector(openAbout), keyEquivalent: "")
        aboutItem.target = self
        menu?.addItem(aboutItem)

        menu?.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Apollo Monitor", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu?.addItem(quitItem)
    }

    // MARK: - Click Handling

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            // Right-click: show menu
            statusItem?.menu = menu
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil
        } else {
            // Left-click: show popover
            togglePopover()
        }
    }

    private func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Menu Actions

    @objc private func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            settingsWindow?.title = "Settings"
            settingsWindow?.contentViewController = NSHostingController(rootView: settingsView)
            settingsWindow?.center()
            settingsWindow?.isReleasedWhenClosed = false
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openAbout() {
        if aboutWindow == nil {
            let aboutView = AboutView()
            aboutWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 360, height: 420),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            aboutWindow?.title = "About Apollo Monitor"
            aboutWindow?.contentViewController = NSHostingController(rootView: aboutView)
            aboutWindow?.center()
            aboutWindow?.isReleasedWhenClosed = false
        }

        aboutWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
