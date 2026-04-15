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
        ZStack {
            LockInLiquidBackground(density: .compact)

            VStack(spacing: 0) {
                header

                if let report = store.activationReport {
                    StatusBanner(report: report) {
                        store.dismissActivationReport()
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
                } else if store.notificationStatus != .authorized {
                    PermissionBanner(
                        description: store.notificationStatus.description,
                        actionTitle: "Help"
                    ) {
                        showingHelpSheet = true
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
                }

                modeList

                startupSection

                footerBar
            }
        }
        .frame(width: 360)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingEditSheet) {
            EditModeView(mode: editingMode)
                .environmentObject(store)
        }
        .sheet(isPresented: $showingHelpSheet) {
            HelpView(notificationStatus: store.notificationStatus)
        }
        .alert("Reset Lock-In?", isPresented: $showingResetAlert) {
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

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(LockInTheme.primaryGradient)
                    .frame(width: 42, height: 42)
                Image(systemName: "rectangle.3.group.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .shadow(color: LockInTheme.blue.opacity(0.28), radius: 16, y: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text("Lock-In")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(LockInTheme.ink)
                Text(activeSubtitle)
                    .font(.caption)
                    .foregroundStyle(LockInTheme.mutedInk)
            }

            Spacer()

            Button {
                editingMode = nil
                showingEditSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.headline.weight(.semibold))
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.10), in: Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(LockInTheme.ink)
            .help("Create mode")
        }
        .padding(16)
    }

    private var modeList: some View {
        ScrollView {
            VStack(spacing: 9) {
                if store.modes.isEmpty {
                    emptyModeState
                } else {
                    ForEach(store.modes) { mode in
                        ModeRowView(
                            mode: mode,
                            isActive: store.activeModeId == mode.id,
                            onActivate: {
                                activate(mode)
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
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(maxHeight: 330)
    }

    private var emptyModeState: some View {
        VStack(spacing: 10) {
            LockInIconBadge(systemName: "sparkles", tint: LockInTheme.lavender)
            Text("No modes yet")
                .font(.headline)
                .foregroundStyle(LockInTheme.ink)
            Text("Create a mode to launch apps, close distractions, and start faster.")
                .font(.caption)
                .foregroundStyle(LockInTheme.mutedInk)
                .multilineTextAlignment(.center)
            Button("Create mode") {
                editingMode = nil
                showingEditSheet = true
            }
            .buttonStyle(LockInPrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .lockInGlass(cornerRadius: 20, opacity: 0.07)
    }

    private var startupSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                LockInIconBadge(systemName: "power", tint: LockInTheme.mint)
                    .frame(width: 30, height: 30)

                Toggle("Open at login", isOn: Binding(
                    get: { launchAtLoginEnabled },
                    set: { updateLaunchAtLogin(to: $0) }
                ))
                .toggleStyle(.switch)
                .tint(LockInTheme.cyan)
                .foregroundStyle(LockInTheme.ink)

                Spacer()
            }

            if let launchAtLoginMessage {
                Text(launchAtLoginMessage)
                    .font(.caption)
                    .foregroundStyle(LockInTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .lockInGlass(cornerRadius: 18, opacity: 0.055)
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }

    private var footerBar: some View {
        HStack(spacing: 8) {
            Button("Help") {
                showingHelpSheet = true
            }
            .buttonStyle(.plain)

            Button("Edit modes") {
                editingMode = nil
                showingEditSheet = true
            }
            .buttonStyle(.plain)

            Button("Reset") {
                showingResetAlert = true
            }
            .buttonStyle(.plain)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(LockInTheme.mutedInk)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.12))
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

    private func activate(_ mode: Mode) {
        let report = ModeActivator.activate(mode: mode)
        store.setActiveMode(mode)
        store.postActivationReport(report)
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
                .font(.headline)
            VStack(alignment: .leading, spacing: 4) {
                Text(report.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LockInTheme.ink)
                if let firstDetail = report.details.first {
                    Text(firstDetail)
                        .font(.caption)
                        .foregroundStyle(LockInTheme.mutedInk)
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
            .foregroundStyle(LockInTheme.faintInk)
        }
        .padding(12)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
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
            return Color.green.opacity(0.12)
        case .warning:
            return Color.orange.opacity(0.12)
        case .failure:
            return Color.red.opacity(0.12)
        }
    }
}

private struct PermissionBanner: View {
    let description: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            LockInIconBadge(systemName: "bell.badge", tint: LockInTheme.amber)
            Text(description)
                .font(.caption)
                .foregroundStyle(LockInTheme.mutedInk)
                .lineLimit(2)
            Spacer()
            Button(actionTitle, action: action)
                .buttonStyle(.plain)
                .foregroundStyle(LockInTheme.blue)
                .font(.caption.weight(.semibold))
        }
        .padding(12)
        .background(LockInTheme.amber.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(LockInTheme.amber.opacity(0.22), lineWidth: 1)
        )
    }
}

private struct ModeRowView: View {
    let mode: Mode
    let isActive: Bool
    let onActivate: () -> Void
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: mode.colorHex))
                .frame(width: 12, height: 12)
                .shadow(color: Color(hex: mode.colorHex).opacity(0.45), radius: 8, y: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(mode.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LockInTheme.ink)
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(LockInTheme.mutedInk)
            }

            Spacer()

            Button("Change") {
                onEdit()
            }
            .buttonStyle(.plain)
            .font(.caption.weight(.semibold))
            .foregroundStyle(LockInTheme.ink.opacity(0.82))

            Button(isActive ? "Active" : "Start") {
                if !isActive {
                    onActivate()
                }
            }
            .buttonStyle(.plain)
            .font(.caption.weight(.semibold))
            .foregroundStyle(isActive ? LockInTheme.mint : LockInTheme.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                isActive ? LockInTheme.mint.opacity(0.12) : LockInTheme.blue.opacity(0.18),
                in: Capsule()
            )
            .disabled(isActive)

            Menu {
                Button("Duplicate", action: onDuplicate)
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 18, height: 18)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .foregroundStyle(LockInTheme.mutedInk)
        }
        .padding(12)
        .lockInGlass(cornerRadius: 18, opacity: 0.055, highlighted: isActive || isHovered)
        .scaleEffect(isHovered ? 1.006 : 1)
        .animation(.easeOut(duration: 0.16), value: isHovered)
        .onHover { isHovered = $0 }
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
        ZStack {
            LockInLiquidBackground(density: .compact)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 14) {
                        LockInIconBadge(systemName: "questionmark.circle", tint: LockInTheme.cyan)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Help and beta checklist")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(LockInTheme.ink)
                            Text("A quick guide for permissions, startup, and testing the full mode flow.")
                                .font(.subheadline)
                                .foregroundStyle(LockInTheme.mutedInk)
                        }
                    }

                    HelpCard(title: "Before beta testing", icon: "checklist", tint: LockInTheme.mint) {
                        HelpTip("Grant Automation access the first time Lock-In tries to close another app.")
                        HelpTip("If quitting apps fails, open System Settings > Privacy & Security > Automation and allow Lock-In.")
                        HelpTip(notificationStatus.description)
                        HelpTip("If startup requires approval, open System Settings > General > Login Items and enable Lock-In.")
                    }

                    HelpCard(title: "Choosing apps", icon: "square.grid.2x2", tint: LockInTheme.blue) {
                        HelpTip("Use the app picker in onboarding or edit mode. It shows installed apps automatically, so testers do not need bundle IDs.")
                        HelpTip("If an app was moved or deleted, open the mode editor and choose it again from the current app list.")
                    }

                    HelpCard(title: "Tester checklist", icon: "sparkles", tint: LockInTheme.lavender) {
                        HelpTip("Verify launch, quit, URL open, timer, notification, duplicate, reset, and startup behavior.")
                        HelpTip("Try one invalid URL and one unavailable app to confirm activation feedback is clear.")
                        HelpTip("Confirm the active mode label updates after activation.")
                    }
                }
                .padding(24)
            }
        }
        .frame(minWidth: 560, minHeight: 500)
        .preferredColorScheme(.dark)
    }
}

private struct HelpCard<Content: View>: View {
    let title: String
    let icon: String
    let tint: Color
    let content: Content

    init(title: String, icon: String, tint: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                LockInIconBadge(systemName: icon, tint: tint)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(LockInTheme.ink)
            }

            content
        }
        .padding(16)
        .lockInGlass(cornerRadius: 20, opacity: 0.07)
    }
}

private struct HelpTip: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(LockInTheme.cyan.opacity(0.72))
                .frame(width: 6, height: 6)
                .padding(.top, 7)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(LockInTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
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
