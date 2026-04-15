import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: ModeStore
    @StateObject private var appCatalog = AppCatalogStore()

    let onFinish: () -> Void

    @State private var draftModes: [Mode] = ModeStore.defaults
    @State private var isVisible = false

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        introCard
                            .modifier(AppearMotion(delay: 0.05, isVisible: isVisible))
                        permissionCard
                            .modifier(AppearMotion(delay: 0.12, isVisible: isVisible))

                        VStack(alignment: .leading, spacing: 16) {
                            Text("Customize your starter modes")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(LockInTheme.ink)
                            Text("Set the apps, URLs, timers, and sounds you want ready from day one. You can always edit these later from the menu bar.")
                                .foregroundStyle(LockInTheme.mutedInk)

                            ForEach(Array($draftModes.enumerated()), id: \.element.id) { index, $mode in
                                OnboardingModeCard(mode: $mode)
                                    .modifier(AppearMotion(delay: 0.18 + (Double(index) * 0.08), isVisible: isVisible))
                            }
                        }
                    }
                    .padding(28)
                }

                Divider()

                HStack {
                    Text("You can revise everything later from the menu bar.")
                        .font(.footnote)
                        .foregroundStyle(LockInTheme.mutedInk)
                    Spacer()
                    Button("Use defaults") {
                        finish(with: ModeStore.defaults)
                    }
                    .buttonStyle(LockInSecondaryButtonStyle())

                    Button("Save and start") {
                        finish(with: draftModes)
                    }
                    .buttonStyle(LockInPrimaryButtonStyle())
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 18)
                .background(Color.black.opacity(0.20))
            }
        }
        .frame(minWidth: 880, minHeight: 720)
        .background(Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(LockInTheme.strongBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 30, y: 18)
        .environmentObject(appCatalog)
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.75, dampingFraction: 0.84)) {
                isVisible = true
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("New Mac setup", systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(LockInTheme.cyan)
            Text("Welcome to Lock-In")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(LockInTheme.ink)
            Text("Shape a few focused modes now and the menu bar app will feel personal from the very first click.")
                .font(.title3)
                .foregroundStyle(LockInTheme.mutedInk)

            HStack(spacing: 12) {
                OnboardingStatPill(title: "Launch", subtitle: "work apps")
                OnboardingStatPill(title: "Close", subtitle: "distractions")
                OnboardingStatPill(title: "Start", subtitle: "timers")
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(28)
        .background(
            ZStack {
                LockInTheme.heroGradient
                Color.white.opacity(0.025)
            }
        )
        .overlay(alignment: .bottom) {
            Divider()
        }
        .modifier(AppearMotion(delay: 0.0, isVisible: isVisible))
    }

    private var backgroundLayer: some View {
        LockInLiquidBackground(density: .spacious)
    }

    private var introCard: some View {
        InfoCard(
            title: "How it works",
            message: "A mode can launch apps, close distractions, open URLs, start a timer, and optionally play a sound. Pick the apps you use most and give each mode a clear purpose.",
            icon: "bolt.badge.clock"
        )
    }

    private var permissionCard: some View {
        InfoCard(
            title: "Permissions you may see",
            message: "macOS may ask for Notifications and Automation access. Allowing Automation lets Lock-In close apps for you. If you skip it, launching will still work but quitting other apps may fail.",
            icon: "hand.raised.square"
        )
    }

    private func finish(with modes: [Mode]) {
        store.completeOnboarding(with: modes)
        onFinish()
    }
}

private struct OnboardingStatPill: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(LockInTheme.ink)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(LockInTheme.mutedInk)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
        )
    }
}

private struct OnboardingModeCard: View {
    @Binding var mode: Mode
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Circle()
                    .fill(Color(hex: mode.colorHex))
                    .frame(width: 14, height: 14)
                TextField("Mode name", text: $mode.name)
                    .font(.headline)
                    .foregroundStyle(LockInTheme.ink)
                Spacer()
                Stepper("Timer \(mode.timerMinutes)m", value: $mode.timerMinutes, in: 0...180)
                    .labelsHidden()
                Text("\(mode.timerMinutes)m")
                    .foregroundStyle(LockInTheme.mutedInk)
                    .font(.subheadline.monospacedDigit())
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Apps to launch")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LockInTheme.ink.opacity(0.92))
                InstalledAppSelectionField(
                    bundleIdentifiers: $mode.appsToLaunch,
                    emptyState: "Choose the apps that should open for this mode.",
                    buttonTitle: "Choose launch apps"
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Apps to quit")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LockInTheme.ink.opacity(0.92))
                InstalledAppSelectionField(
                    bundleIdentifiers: $mode.appsToQuit,
                    emptyState: "Choose the apps that should close when this mode starts.",
                    buttonTitle: "Choose apps to quit"
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("URLs to open")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LockInTheme.ink.opacity(0.92))
                EditableStringList(items: $mode.urlsToOpen, placeholder: "https://example.com", addLabel: "Add URL")
            }

            Toggle("Play a sound when activating this mode", isOn: $mode.soundEnabled)
                .toggleStyle(.switch)
                .tint(LockInTheme.cyan)
                .foregroundStyle(LockInTheme.ink.opacity(0.88))

            Text("Choose from the apps already installed on this Mac. You can change these later from the menu bar.")
                .font(.footnote)
                .foregroundStyle(LockInTheme.mutedInk)
        }
        .padding(20)
        .lockInGlass(cornerRadius: 22, opacity: 0.075, highlighted: isHovered)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.easeOut(duration: 0.18), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

private struct EditableStringList: View {
    @Binding var items: [String]

    let placeholder: String
    let addLabel: String

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, _ in
                HStack {
                    TextField(
                        placeholder,
                        text: Binding(
                            get: { items[index] },
                            set: { items[index] = $0 }
                        )
                    )
                    .textFieldStyle(.plain)
                    .foregroundStyle(LockInTheme.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(LockInTheme.border, lineWidth: 1)
                    )

                    Button {
                        removeRow(at: index)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(LockInTheme.faintInk)
                }
            }

            Button(addLabel) {
                items.append("")
            }
            .buttonStyle(LockInSecondaryButtonStyle())
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            if items.isEmpty {
                items = [""]
            }
        }
    }

    private func removeRow(at index: Int) {
        guard items.indices.contains(index) else { return }
        items.remove(at: index)
        if items.isEmpty {
            items = [""]
        }
    }
}

private struct InfoCard: View {
    let title: String
    let message: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(LockInTheme.blue)
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(LockInTheme.ink)
                Text(message)
                    .foregroundStyle(LockInTheme.mutedInk)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .lockInGlass(cornerRadius: 20, opacity: 0.07)
    }
}

private struct AppearMotion: ViewModifier {
    let delay: Double
    let isVisible: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 24)
            .scaleEffect(isVisible ? 1 : 0.98)
            .animation(
                .spring(response: 0.75, dampingFraction: 0.84).delay(delay),
                value: isVisible
            )
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
