import AppKit
import SwiftUI
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private(set) var apollo: ApolloController?
    private(set) var discovery: NetworkDiscovery?
    private var settingsWindow: NSWindow?
    private var aboutWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        apollo = ApolloController()
        discovery = NetworkDiscovery()

        setupStatusItem()
        setupPopover()

        NSApp.setActivationPolicy(.accessory)

        // Start Bonjour discovery in background
        discovery?.startBrowsing()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }

        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let image = NSImage(systemSymbolName: "dial.medium.fill", accessibilityDescription: "Apollo Monitor")?
            .withSymbolConfiguration(config)
        image?.isTemplate = true

        button.image = image
        button.target = self
        button.action = #selector(togglePopover)

        button.setAccessibilityLabel("Apollo Monitor")
        button.setAccessibilityHelp("Click to open volume controls")
    }

    private func setupPopover() {
        guard let apollo = apollo, let discovery = discovery else { return }

        popover = NSPopover()
        popover?.contentSize = NSSize(width: 280, height: 380)
        popover?.behavior = .transient
        popover?.animates = true
        popover?.contentViewController = NSHostingController(
            rootView: MonitorView(
                apollo: apollo,
                onOpenSettings: { [weak self] in self?.openSettings() },
                onOpenAbout: { [weak self] in self?.openAbout() },
                onQuit: { NSApp.terminate(nil) }
            )
        )
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Windows

    func openSettings() {
        guard let apollo = apollo, let discovery = discovery else { return }
        popover?.performClose(nil)

        if settingsWindow == nil {
            let settingsView = SettingsView(apollo: apollo, discovery: discovery)
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 400),
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

    func openAbout() {
        popover?.performClose(nil)

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
}
