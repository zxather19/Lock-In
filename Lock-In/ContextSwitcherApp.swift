import AppKit
import SwiftUI

@main
struct ContextSwitcherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private let store = ModeStore()
    private var onboardingWindow: NSWindow?
    private var observers: [NSObjectProtocol] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationService.requestPermission()
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "rectangle.3.group",
                accessibilityDescription: "Context Switcher"
            )
            button.image?.isTemplate = true
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        popover.contentSize = NSSize(width: 320, height: 420)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView().environmentObject(store)
        )

        let observer = NotificationCenter.default.addObserver(
            forName: .reopenOnboardingRequested,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.showOnboardingWindow()
        }
        observers.append(observer)

        if !store.hasCompletedOnboarding {
            showOnboardingWindow()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func showOnboardingWindow() {
        if let onboardingWindow {
            onboardingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let onboardingView = OnboardingView { [weak self] in
            self?.closeOnboardingWindow()
        }
        .environmentObject(store)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 740),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Welcome to Context Switcher"
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.toolbarStyle = .unifiedCompact
        window.contentViewController = NSHostingController(rootView: onboardingView)
        window.makeKeyAndOrderFront(nil)

        onboardingWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }

    private func closeOnboardingWindow() {
        onboardingWindow?.close()
        onboardingWindow = nil
    }
}
