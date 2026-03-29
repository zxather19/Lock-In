import AppKit
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var store: ModeStore
    @State private var showingEditSheet = false
    @State private var showingHelpSheet = false
    @State private var editingMode: Mode?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Context Switcher")
                    .font(.headline)
                Spacer()
                Button("Change mode") {
                    editingMode = store.modes.first
                    showingEditSheet = true
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Button {
                    editingMode = nil
                    showingEditSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
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
                            }
                        )
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: 320)

            Divider()

            if !store.modes.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(.secondary)
                    Text("Want to change a mode? Use the Change button on any row.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
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
        .task {
            await store.refreshNotificationStatus()
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

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(hex: mode.colorHex))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(mode.name)
                    .font(.subheadline.weight(.medium))
                Text("Launch \(mode.appsToLaunch.count) apps, quit \(mode.appsToQuit.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isActive {
                Image(systemName: "checkmark")
                    .foregroundStyle(.secondary)
            }

            Button("Change") {
                onEdit()
            }
            .buttonStyle(.borderless)

            Button("Activate") {
                onActivate()
            }
            .buttonStyle(.borderless)
            .disabled(isActive)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        )
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
