import Foundation

struct Mode: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var colorHex: String
    var appsToLaunch: [String]
    var appsToQuit: [String]
    var urlsToOpen: [String]
    var timerMinutes: Int
    var soundEnabled: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String,
        appsToLaunch: [String] = [],
        appsToQuit: [String] = [],
        urlsToOpen: [String] = [],
        timerMinutes: Int = 0,
        soundEnabled: Bool = true,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.appsToLaunch = appsToLaunch
        self.appsToQuit = appsToQuit
        self.urlsToOpen = urlsToOpen
        self.timerMinutes = max(0, timerMinutes)
        self.soundEnabled = soundEnabled
        self.createdAt = createdAt
    }

    func sanitizedForSave() -> Mode {
        Mode(
            id: id,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            colorHex: colorHex,
            appsToLaunch: normalized(strings: appsToLaunch),
            appsToQuit: normalized(strings: appsToQuit),
            urlsToOpen: normalized(strings: urlsToOpen),
            timerMinutes: max(0, timerMinutes),
            soundEnabled: soundEnabled,
            createdAt: createdAt
        )
    }

    private func normalized(strings: [String]) -> [String] {
        strings
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
