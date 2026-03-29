import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: ModeStore
    @StateObject private var appCatalog = AppCatalogStore()

    let onFinish: () -> Void

    @State private var draftModes: [Mode] = ModeStore.defaults
    @State private var isVisible = false
    @State private var animateGradient = false

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
                            Text("Set the apps, URLs, timers, and sounds you want ready from day one. You can always edit these later from the menu bar.")
                                .foregroundStyle(.secondary)

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
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Use defaults") {
                        finish(with: ModeStore.defaults)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())

                    Button("Save and start") {
                        finish(with: draftModes)
                    }
                    .buttonStyle(.plain)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.21, green: 0.46, blue: 0.84),
                                Color(red: 0.31, green: 0.72, blue: 0.78)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Capsule()
                    )
                    .foregroundStyle(.white)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 18)
                .background(.regularMaterial)
            }
        }
        .frame(minWidth: 880, minHeight: 720)
        .background(Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 30, y: 18)
        .environmentObject(appCatalog)
        .onAppear {
            withAnimation(.spring(response: 0.75, dampingFraction: 0.84)) {
                isVisible = true
            }

            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("New Mac setup", systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(red: 0.77, green: 0.76, blue: 0.97))
            Text("Welcome to Context Switcher")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Shape a few focused modes now and the menu bar app will feel personal from the very first click.")
                .font(.title3)
                .foregroundStyle(Color.white.opacity(0.72))

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
                LinearGradient(
                    colors: [
                        Color(red: 0.20, green: 0.19, blue: 0.34).opacity(0.92),
                        Color(red: 0.12, green: 0.14, blue: 0.24).opacity(0.86)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RoundedRectangle(cornerRadius: 0, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.75))
            }
        )
        .overlay(alignment: .bottom) {
            Divider()
        }
        .modifier(AppearMotion(delay: 0.0, isVisible: isVisible))
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.07, blue: 0.12),
                    Color(red: 0.09, green: 0.10, blue: 0.17),
                    Color(red: 0.13, green: 0.10, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 0.53, green: 0.73, blue: 0.84).opacity(0.22))
                .frame(width: 360, height: 360)
                .blur(radius: 28)
                .offset(x: animateGradient ? 240 : 140, y: animateGradient ? -220 : -150)

            Circle()
                .fill(Color(red: 0.77, green: 0.67, blue: 0.86).opacity(0.22))
                .frame(width: 420, height: 420)
                .blur(radius: 32)
                .offset(x: animateGradient ? -250 : -140, y: animateGradient ? 250 : 180)

            Circle()
                .fill(Color(red: 0.99, green: 0.83, blue: 0.86).opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 46)
                .offset(x: 0, y: -260)
        }
        .ignoresSafeArea()
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
            message: "macOS may ask for Notifications and Automation access. Allowing Automation lets Context Switcher close apps for you. If you skip it, launching will still work but quitting other apps may fail.",
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
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.68))
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
                    .foregroundStyle(.white)
                Spacer()
                Stepper("Timer \(mode.timerMinutes)m", value: $mode.timerMinutes, in: 0...180)
                    .labelsHidden()
                Text("\(mode.timerMinutes)m")
                    .foregroundStyle(Color.white.opacity(0.68))
                    .font(.subheadline.monospacedDigit())
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Apps to launch")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.92))
                InstalledAppSelectionField(
                    bundleIdentifiers: $mode.appsToLaunch,
                    emptyState: "Choose the apps that should open for this mode.",
                    buttonTitle: "Choose launch apps"
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Apps to quit")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.92))
                InstalledAppSelectionField(
                    bundleIdentifiers: $mode.appsToQuit,
                    emptyState: "Choose the apps that should close when this mode starts.",
                    buttonTitle: "Choose apps to quit"
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("URLs to open")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.92))
                EditableStringList(items: $mode.urlsToOpen, placeholder: "https://example.com", addLabel: "Add URL")
            }

            Toggle("Play a sound when activating this mode", isOn: $mode.soundEnabled)
                .toggleStyle(.switch)
                .foregroundStyle(Color.white.opacity(0.88))

            Text("Choose from the apps already installed on this Mac. You can change these later from the menu bar.")
                .font(.footnote)
                .foregroundStyle(Color.white.opacity(0.62))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    Color.white.opacity(isHovered ? 0.22 : 0.12),
                    lineWidth: 1
                )
        )
        .shadow(
            color: Color(red: 0.02, green: 0.02, blue: 0.06).opacity(isHovered ? 0.42 : 0.26),
            radius: isHovered ? 24 : 14,
            y: isHovered ? 12 : 8
        )
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
                    .textFieldStyle(.roundedBorder)
                    .colorScheme(.dark)

                    Button {
                        removeRow(at: index)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }

            Button(addLabel) {
                items.append("")
            }
            .buttonStyle(.link)
            .foregroundStyle(Color(red: 0.75, green: 0.82, blue: 0.98))
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
                .foregroundStyle(Color(red: 0.74, green: 0.83, blue: 0.98))
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(message)
                    .foregroundStyle(Color.white.opacity(0.7))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
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
