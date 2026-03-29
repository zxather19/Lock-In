import Combine
import Foundation

extension Notification.Name {
    static let reopenOnboardingRequested = Notification.Name("reopenOnboardingRequested")
}

@MainActor
final class ModeStore: ObservableObject {
    @Published var modes: [Mode] = []
    @Published var activeModeId: UUID?
    @Published var activationReport: ActivationReport?
    @Published var notificationStatus: NotificationAuthorizationState = .unknown
    @Published var hasCompletedOnboarding: Bool

    private let modesKey: String
    private let activeModeKey: String
    private let onboardingKey: String
    private let userDefaults: UserDefaults

    init(
        userDefaults: UserDefaults = .standard,
        modesKey: String = "saved_modes",
        activeModeKey: String = "active_mode_id",
        onboardingKey: String = "has_completed_onboarding"
    ) {
        self.userDefaults = userDefaults
        self.modesKey = modesKey
        self.activeModeKey = activeModeKey
        self.onboardingKey = onboardingKey
        self.hasCompletedOnboarding = userDefaults.bool(forKey: onboardingKey)
        load()
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(modes)
            userDefaults.set(data, forKey: modesKey)
        } catch {}
    }

    func upsert(_ mode: Mode) {
        let sanitizedMode = mode.sanitizedForSave()
        if let index = modes.firstIndex(where: { $0.id == mode.id }) {
            modes[index] = sanitizedMode
        } else {
            modes.append(sanitizedMode)
        }
        save()
    }

    func delete(_ mode: Mode) {
        modes.removeAll { $0.id == mode.id }
        if activeModeId == mode.id {
            activeModeId = nil
            userDefaults.removeObject(forKey: activeModeKey)
        }
        save()
    }

    func setActiveMode(_ mode: Mode?) {
        activeModeId = mode?.id
        if let id = mode?.id {
            userDefaults.set(id.uuidString, forKey: activeModeKey)
        } else {
            userDefaults.removeObject(forKey: activeModeKey)
        }
    }

    func postActivationReport(_ report: ActivationReport) {
        activationReport = report
    }

    func dismissActivationReport() {
        activationReport = nil
    }

    func refreshNotificationStatus() async {
        notificationStatus = await NotificationService.authorizationState()
    }

    func completeOnboarding(with modes: [Mode]) {
        self.modes = modes.map { $0.sanitizedForSave() }
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: onboardingKey)
        save()
    }

    func resetForOnboarding() {
        modes = Self.defaults
        activeModeId = nil
        activationReport = nil
        hasCompletedOnboarding = false

        userDefaults.removeObject(forKey: activeModeKey)
        userDefaults.removeObject(forKey: modesKey)
        userDefaults.set(false, forKey: onboardingKey)

        save()
    }

    static let defaults: [Mode] = [
        Mode(
            name: "Deep Work",
            colorHex: "#534AB7",
            appsToLaunch: [
                "notion.id",
                "com.microsoft.VSCode"
            ],
            appsToQuit: [
                "com.atebits.Tweetie2",
                "com.hnc.Discord"
            ],
            urlsToOpen: [
                "https://docs.google.com"
            ],
            timerMinutes: 90,
            soundEnabled: true
        ),
        Mode(
            name: "Lecture",
            colorHex: "#0F6E56",
            appsToLaunch: [
                "us.zoom.xos"
            ],
            appsToQuit: [
                "com.hnc.Discord",
                "com.twitter.twitter-mac"
            ],
            urlsToOpen: [],
            timerMinutes: 0,
            soundEnabled: false
        ),
        Mode(
            name: "Break",
            colorHex: "#B88780",
            appsToLaunch: [
                "com.spotify.client"
            ],
            appsToQuit: [],
            urlsToOpen: [],
            timerMinutes: 15,
            soundEnabled: true
        )
    ]

    private func load() {
        if let rawActiveModeId = userDefaults.string(forKey: activeModeKey) {
            activeModeId = UUID(uuidString: rawActiveModeId)
        }

        guard let data = userDefaults.data(forKey: modesKey) else {
            modes = Self.defaults
            save()
            return
        }

        do {
            modes = try JSONDecoder().decode([Mode].self, from: data)
        } catch {
            modes = Self.defaults
            save()
        }

        if let activeModeId, !modes.contains(where: { $0.id == activeModeId }) {
            setActiveMode(nil)
        }
    }
}
