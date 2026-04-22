import AppKit
import Foundation

final class ModeActivator {
    private static var timer: Timer?

    static func activate(mode: Mode) -> ActivationReport {
        var details: [String] = []
        let quitMessages = quitApps(bundleIDs: mode.appsToQuit)
        let launchMessages = launchApps(bundleIDs: mode.appsToLaunch)
        let urlMessages = openURLs(urlStrings: mode.urlsToOpen)

        details.append(contentsOf: quitMessages)
        details.append(contentsOf: launchMessages)
        details.append(contentsOf: urlMessages)

        if mode.timerMinutes > 0 {
            startTimer(minutes: mode.timerMinutes, modeName: mode.name)
            details.append("Started a \(mode.timerMinutes)-minute timer.")
        } else {
            timer?.invalidate()
            timer = nil
            details.append("No timer started for this mode.")
        }

        if mode.soundEnabled {
            playSound()
            details.append("Played activation sound.")
        }

        let failures = details.filter { $0.hasPrefix("Couldn’t") || $0.hasPrefix("Invalid") }
        let level: ActivationReport.Level
        if failures.count == details.count, !failures.isEmpty {
            level = .failure
        } else if failures.isEmpty {
            level = .success
        } else {
            level = .warning
        }

        return ActivationReport(
            level: level,
            title: "Activated \(mode.name)",
            details: details
        )
    }

    private static func playSound() {
        DispatchQueue.main.async {
            (NSSound(named: NSSound.Name("Funk")) ?? NSSound(named: NSSound.Name("Glass")))?.play()
        }
    }

    private static func launchApps(bundleIDs: [String]) -> [String] {
        guard !bundleIDs.isEmpty else { return ["No apps to launch."] }

        var messages: [String] = []
        for bundleID in bundleIDs {
            guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
                messages.append("Couldn’t find app for bundle ID \(bundleID).")
                continue
            }

            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = false
            NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { _, error in
                if let error {
                    NSLog("Lock-In launch error for %@: %@", bundleID, error.localizedDescription)
                }
            }
            messages.append("Launched \(bundleID).")
        }
        return messages
    }

    private static func quitApps(bundleIDs: [String]) -> [String] {
        guard !bundleIDs.isEmpty else { return ["No apps to quit."] }

        var messages: [String] = []
        for bundleID in bundleIDs {
            let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            if runningApps.isEmpty {
                messages.append("No running app found for \(bundleID).")
                continue
            }

            for app in runningApps {
                if app.terminate() {
                    messages.append("Quit \(bundleID).")
                } else {
                    messages.append("Couldn’t quit \(bundleID). Check Automation permissions.")
                }
            }
        }
        return messages
    }

    private static func openURLs(urlStrings: [String]) -> [String] {
        guard !urlStrings.isEmpty else { return ["No URLs to open."] }

        var messages: [String] = []
        for urlString in urlStrings {
            guard
                let url = URL(string: urlString),
                let scheme = url.scheme,
                !scheme.isEmpty
            else {
                messages.append("Invalid URL: \(urlString).")
                continue
            }

            if NSWorkspace.shared.open(url) {
                messages.append("Opened \(url.host ?? url.absoluteString).")
            } else {
                messages.append("Couldn’t open URL \(urlString).")
            }
        }
        return messages
    }

    private static func startTimer(minutes: Int, modeName: String) {
        timer?.invalidate()
        guard minutes > 0 else { return }
        DispatchQueue.main.async {
            timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(minutes * 60), repeats: false) { _ in
                NotificationService.sendPomodoroEnd(modeName: modeName)
            }
        }
    }
}
