//
//  Lock_InTests.swift
//  Lock-InTests
//
//  Created by Shaurya Tayal on 3/13/26.
//

import Foundation
import Testing
@testable import Lock_In

struct Lock_InTests {
    @Test func modeSanitizationTrimsWhitespaceAndDropsEmptyEntries() async throws {
        let mode = await MainActor.run {
            Mode(
                name: "  Deep Work  ",
                colorHex: "#123456",
                appsToLaunch: [" com.microsoft.VSCode ", "   "],
                appsToQuit: [" com.hnc.Discord "],
                urlsToOpen: [" https://example.com ", ""],
                timerMinutes: -3,
                soundEnabled: true
            ).sanitizedForSave()
        }

        await MainActor.run {
            #expect(mode.name == "Deep Work")
            #expect(mode.appsToLaunch == ["com.microsoft.VSCode"])
            #expect(mode.appsToQuit == ["com.hnc.Discord"])
            #expect(mode.urlsToOpen == ["https://example.com"])
            #expect(mode.timerMinutes == 0)
        }
    }

    @Test func storePersistsModesAndActiveMode() async throws {
        let suiteName = "Lock-InTests-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Could not create isolated UserDefaults suite.")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)

        let store = await MainActor.run {
            ModeStore(
                userDefaults: defaults,
                modesKey: "test_modes",
                activeModeKey: "test_active_mode"
            )
        }

        let createdMode = Mode(
            name: "Beta",
            colorHex: "#654321",
            appsToLaunch: ["com.apple.Terminal"]
        )

        await MainActor.run {
            store.upsert(createdMode)
            store.setActiveMode(createdMode)
        }

        let reloadedStore = await MainActor.run {
            ModeStore(
                userDefaults: defaults,
                modesKey: "test_modes",
                activeModeKey: "test_active_mode"
            )
        }

        await MainActor.run {
            #expect(reloadedStore.modes.contains(where: { $0.name == "Beta" }))
            #expect(reloadedStore.activeModeId == createdMode.id)
        }

        defaults.removePersistentDomain(forName: suiteName)
    }

}
