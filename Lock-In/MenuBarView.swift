import AppKit
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var store: ModeStore
    @State private var showingEditSheet = false
    @State private var showingHelpSheet = false
    @State private var showingResetAlert = false
    @State private var showingStartupErrorAlert = false
    @State private var editingMode: Mode?
    @State private var launchAtLoginEnabled = false
    @State private var launchAtLoginMessage: String?
    @State private var startupErrorMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lock-In")
                        .font(.headline.weight(.semibold))
                    Text(activeSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    editingMode = nil
                    showingEditSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                }
                .buttonStyle(.plain)
                .help("Create mode")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if let report = store.activationReport {
                StatusBanner(report: report) {
                    store.dismissActivationReport()
                }
                Divider()
            } else if store.notificationStatus != .authorized {
                PermissionBanner(
                    description: store.notificationStatus.description,
                    actionTitle: "Help"
                ) {
                    showingHelpSheet = true
                }
                Divider()
            }

            Divider()

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(store.modes) { mode in
                        ModeRowView(
                            mode: mode,
                            isActive: store.activeModeId == mode.id,
                            onActivate: {
                                let report = ModeActivator.activate(mode: mode)
                                store.setActiveMode(mode)
                                store.postActivationReport(report)
                            },
                            onEdit: {
                                editingMode = mode
                                showingEditSheet = true
                            },
                            onDuplicate: {
                                store.duplicate(mode)
                            }
                        )
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: 320)

            Divider()

            HStack(spacing: 10) {
                Toggle("Open at login", isOn: Binding(
                    get: { launchAtLoginEnabled },
                    set: { updateLaunchAtLogin(to: $0) }
                ))
                .toggleStyle(.switch)

                if launchAtLoginMessage != nil {
                    Button("Help") {
                        showingHelpSheet = true
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            if let launchAtLoginMessage {
                Text(launchAtLoginMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
            }

            HStack {
                Button("Help") {
                    showingHelpSheet = true
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Button("Edit modes") {
                    editingMode = nil
                    showingEditSheet = true
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Button("Reset") {
                    showingResetAlert = true
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 320)
        .sheet(isPresented: $showingEditSheet) {
            EditModeView(mode: editingMode)
                .environmentObject(store)
        }
        .sheet(isPresented: $showingHelpSheet) {
            HelpView(notificationStatus: store.notificationStatus)
        }
        .alert("Reset Context Switcher?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset and reopen onboarding", role: .destructive) {
                resetAndReopenOnboarding()
            }
        } message: {
            Text("This will replace your saved modes with the starter defaults and reopen the onboarding window.")
        }
        .alert("Couldn't update startup setting", isPresented: $showingStartupErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(startupErrorMessage)
        }
        .task {
            await store.refreshNotificationStatus()
            refreshLaunchAtLoginState()
        }
    }

    private var activeSubtitle: String {
        guard let activeModeId = store.activeModeId,
              let mode = store.modes.first(where: { $0.id == activeModeId }) else {
            return "\(store.modes.count) modes"
        }
        return "\(mode.name) is active"
    }

    private func resetAndReopenOnboarding() {
        showingEditSheet = false
        store.resetForOnboarding()
        NotificationCenter.default.post(name: .reopenOnboardingRequested, object: nil)
    }

    private func refreshLaunchAtLoginState() {
        let state = LaunchAtLoginManager.currentState()
        launchAtLoginEnabled = state.isEnabled
        launchAtLoginMessage = state.message
    }

    private func updateLaunchAtLogin(to enabled: Bool) {
        do {
            let state = try LaunchAtLoginManager.setEnabled(enabled)
            launchAtLoginEnabled = state.isEnabled
            launchAtLoginMessage = state.message
        } catch {
            refreshLaunchAtLoginState()
            startupErrorMessage = error.localizedDescription
            showingStartupErrorAlert = true
        }
    }
}

private struct StatusBanner: View {
    let report: ActivationReport
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(report.title)
                    .font(.subheadline.weight(.semibold))
                if let firstDetail = report.details.first {
                    Text(firstDetail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(backgroundColor)
    }

    private var iconName: String {
        switch report.level {
        case .success:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .failure:
            return "xmark.octagon.fill"
        }
    }

    private var iconColor: Color {
        switch report.level {
        case .success:
            return .green
        case .warning:
            return .orange
        case .failure:
            return .red
        }
    }

    private var backgroundColor: Color {
        switch report.level {
        case .success:
            return Color.green.opacity(0.08)
        case .warning:
            return Color.orange.opacity(0.08)
        case .failure:
            return Color.red.opacity(0.08)
        }
    }
}

private struct PermissionBanner: View {
    let description: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "bell.badge")
                .foregroundStyle(.orange)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Spacer()
            Button(actionTitle, action: action)
                .buttonStyle(.link)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.08))
    }
}

private struct ModeRowView: View {
    let mode: Mode
    let isActive: Bool
    let onActivate: () -> Void
    let onEdit: () -> Void
    let onDuplicate: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(hex: mode.colorHex))
                .frame(width: 8, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(mode.name)
                    .font(.subheadline.weight(.semibold))
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(isActive ? "Active" : "Start") {
                if !isActive {
                    onActivate()
                }
            }
            .buttonStyle(.plain)
            .font(.caption.weight(.semibold))
            .foregroundStyle(isActive ? .secondary : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(isActive ? 0.04 : 0.08), in: Capsule())
            .disabled(isActive)

            Menu {
                Button("Change", action: onEdit)
                Button("Duplicate", action: onDuplicate)
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 18, height: 18)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(isActive ? 0.08 : 0.045))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(isActive ? 0.12 : 0.05), lineWidth: 1)
        )
    }

    private var summary: String {
        var parts: [String] = []
        if !mode.appsToLaunch.isEmpty {
            parts.append("\(mode.appsToLaunch.count) launch")
        }
        if !mode.appsToQuit.isEmpty {
            parts.append("\(mode.appsToQuit.count) quit")
        }
        if !mode.urlsToOpen.isEmpty {
            parts.append("\(mode.urlsToOpen.count) link")
        }
        if mode.timerMinutes > 0 {
            parts.append("\(mode.timerMinutes)m")
        }
        return parts.isEmpty ? "No actions yet" : parts.joined(separator: " · ")
    }
}

private struct HelpView: View {
    let notificationStatus: NotificationAuthorizationState

    var body: some View {
        NavigationStack {
            List {
                Section("Before beta testing") {
                    Text("Grant Automation access the first time Context Switcher tries to control another app.")
                    Text("If a mode can’t quit another app, open System Settings > Privacy & Security > Automation and allow Context Switcher.")
                    Text(notificationStatus.description)
                    Text("If startup requires approval, open System Settings > General > Login Items and enable Context Switcher.")
                }

                Section("Bundle IDs") {
                    Text("Use exact app bundle IDs in modes. Example: com.microsoft.VSCode")
                    Text("Find bundle IDs with: osascript -e 'id of app \"Notion\"'")
                        .textSelection(.enabled)
                        .font(.system(.body, design: .monospaced))
                }

                Section("Tester checklist") {
                    Text("Verify launch, quit, URL open, timer, and notification behavior with real apps installed on the test Mac.")
                    Text("Try at least one invalid bundle ID and one invalid URL to confirm the app reports the problem clearly.")
                    Text("Confirm the active mode checkmark updates after activation.")
                }
            }
            .navigationTitle("Help")
            .frame(minWidth: 520, minHeight: 420)
        }
    }
}
 
private extension Color {
    init(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if sanitized.hasPrefix("#") {
            sanitized.removeFirst()
        }

        guard
            sanitized.count == 6,
            let value = UInt64(sanitized, radix: 16)
        else {
            self = .gray
            return
        }

        self = Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
