import AppKit
import SwiftUI

@main
struct LockInApp: App {
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
        updateActivationPolicy(showDockIcon: !store.hasCompletedOnboarding)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = Self.menuBarIcon()
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        popover.contentSize = NSSize(width: 360, height: 520)
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
            updateActivationPolicy(showDockIcon: true)
            onboardingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let onboardingView = OnboardingView { [weak self] in
            self?.closeOnboardingWindow()
        }
        .environmentObject(store)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 920, height: 760),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Welcome to Lock-In"
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.toolbarStyle = .unifiedCompact
        window.contentViewController = NSHostingController(rootView: onboardingView)
        window.makeKeyAndOrderFront(nil)

        onboardingWindow = window
        updateActivationPolicy(showDockIcon: true)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func closeOnboardingWindow() {
        onboardingWindow?.close()
        onboardingWindow = nil
        updateActivationPolicy(showDockIcon: false)
    }

    private func updateActivationPolicy(showDockIcon: Bool) {
        NSApp.setActivationPolicy(showDockIcon ? .regular : .accessory)
    }

    private static func menuBarIcon() -> NSImage {
        let bundledAppIcon = Bundle.main.url(forResource: "AppIcon", withExtension: "icns")
            .flatMap { NSImage(contentsOf: $0) }
        let image = NSImage(named: "MenuBarIcon") ??
            bundledAppIcon ??
            NSImage(named: "AppIcon") ??
            NSApplication.shared.applicationIconImage.copy() as? NSImage ??
            NSImage(systemSymbolName: "lock.fill", accessibilityDescription: "Lock-In") ??
            NSImage()
        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = false
        image.accessibilityDescription = "Lock-In"
        return image
    }
}
