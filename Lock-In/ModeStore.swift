import Foundation
import Observation

extension Notification.Name {
    static let reopenOnboardingRequested = Notification.Name("reopenOnboardingRequested")
}

private struct LockInStoreState: Codable {
    var activeModeId: UUID?
    var hasCompletedOnboarding: Bool
}

@MainActor
@Observable
final class ModeStore {
    static let shared = ModeStore()

    var modes: [Mode] = []
    var activeModeId: UUID?
    var activationReport: ActivationReport?
    var notificationStatus: NotificationAuthorizationState = .unknown
    var hasCompletedOnboarding = false

    var activator: ModeActivator?
    var onModesChanged: (([Mode]) -> Void)?

    private let appSupportDirectory: URL
    private let stateFileName: String

    init(
        appSupportDirectory: URL? = nil,
        stateFileName: String = "store-state.json"
    ) {
        self.appSupportDirectory = appSupportDirectory ?? Self.defaultAppSupportDirectory()
        self.stateFileName = stateFileName
        load()
    }

    var storageURL: URL {
        appSupportDirectory.appendingPathComponent("modes.json")
    }

    private var stateURL: URL {
        appSupportDirectory.appendingPathComponent(stateFileName)
    }

    func save() {
        do {
            try FileManager.default.createDirectory(at: appSupportDirectory, withIntermediateDirectories: true)
            let modesData = try JSONEncoder().encode(modes)
            try modesData.write(to: storageURL, options: .atomic)

            let state = LockInStoreState(
                activeModeId: activeModeId,
                hasCompletedOnboarding: hasCompletedOnboarding
            )
            let stateData = try JSONEncoder().encode(state)
            try stateData.write(to: stateURL, options: .atomic)
        } catch {
            print("Lock-In save error: \(error.localizedDescription)")
        }
    }

    func addMode(_ mode: Mode) {
        upsert(mode)
    }

    func updateMode(_ mode: Mode) {
        upsert(mode)
    }

    func upsert(_ mode: Mode) {
        let sanitizedMode = mode.sanitizedForSave()
        if let index = modes.firstIndex(where: { $0.id == mode.id }) {
            modes[index] = sanitizedMode
        } else {
            modes.append(sanitizedMode)
        }
        persistModeMutation()
    }

    func deleteMode(id: UUID) {
        modes.removeAll { $0.id == id }
        if activeModeId == id {
            activeModeId = nil
        }
        persistModeMutation()
    }

    func delete(_ mode: Mode) {
        deleteMode(id: mode.id)
    }

    func duplicate(_ mode: Mode) {
        let copy = Mode(
            name: copyName(for: mode.name),
            colorHex: mode.colorHex,
            appsToLaunch: mode.appsToLaunch,
            appsToQuit: mode.appsToQuit,
            urlsToOpen: mode.urlsToOpen,
            timerMinutes: mode.timerMinutes,
            soundEnabled: mode.soundEnabled,
            shortcut: mode.shortcut,
            schedule: mode.schedule
        ).sanitizedForSave()

        modes.append(copy)
        persistModeMutation()
    }

    func setModes(_ updatedModes: [Mode]) {
        modes = updatedModes.map { $0.sanitizedForSave() }
        if let activeModeId, !modes.contains(where: { $0.id == activeModeId }) {
            self.activeModeId = nil
        }
        persistModeMutation()
    }

    func setActiveMode(_ mode: Mode?) {
        activeModeId = mode?.id
        save()
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
        persistModeMutation()
    }

    func resetForOnboarding() {
        modes = []
        activeModeId = nil
        activationReport = nil
        hasCompletedOnboarding = false
        persistModeMutation()
    }

    func activate(_ mode: Mode) async {
        guard let activator else {
            let report = ActivationReport(
                level: .failure,
                title: "Lock-In couldn't activate this mode",
                details: [],
                warnings: ["The activation engine has not been configured yet."]
            )
            postActivationReport(report)
            return
        }

        let report = await activator.activate(mode: mode)
        setActiveMode(mode)
        postActivationReport(report)
    }

    static let defaults: [Mode] = ModeTemplate.all

    func load() {
        do {
            try FileManager.default.createDirectory(at: appSupportDirectory, withIntermediateDirectories: true)
        } catch {
            print("Lock-In storage directory error: \(error.localizedDescription)")
        }

        if let stateData = try? Data(contentsOf: stateURL),
           let state = try? JSONDecoder().decode(LockInStoreState.self, from: stateData) {
            activeModeId = state.activeModeId
            hasCompletedOnboarding = state.hasCompletedOnboarding
        } else {
            activeModeId = nil
            hasCompletedOnboarding = false
        }

        guard let data = try? Data(contentsOf: storageURL) else {
            modes = []
            save()
            return
        }

        modes = (try? JSONDecoder().decode([Mode].self, from: data)) ?? []

        if let activeModeId, !modes.contains(where: { $0.id == activeModeId }) {
            self.activeModeId = nil
        }
    }

    private func persistModeMutation() {
        save()
        onModesChanged?(modes)
    }

    private func copyName(for name: String) -> String {
        let baseName = "\(name) Copy"
        guard modes.contains(where: { $0.name == baseName }) else {
            return baseName
        }

        var index = 2
        while modes.contains(where: { $0.name == "\(baseName) \(index)" }) {
            index += 1
        }
        return "\(baseName) \(index)"
    }

    private static func defaultAppSupportDirectory() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LockIn", isDirectory: true)
    }
}
