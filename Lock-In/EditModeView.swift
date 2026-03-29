import SwiftUI

struct EditModeView: View {
    @EnvironmentObject private var store: ModeStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appCatalog = AppCatalogStore()

    let mode: Mode?

    @State private var name: String = ""
    @State private var colorHex: String = "#534AB7"
    @State private var appsToLaunch: [String] = [""]
    @State private var appsToQuit: [String] = [""]
    @State private var urlsToOpen: [String] = [""]
    @State private var timerMinutes: Int = 0
    @State private var soundEnabled: Bool = true
    @State private var isVisible = false

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        identitySection
                            .modifier(EditAppearMotion(delay: 0.05, isVisible: isVisible))

                        appSection(
                            title: "Apps to launch",
                            detail: "Pick the apps that define this context.",
                            bundleIdentifiers: $appsToLaunch,
                            emptyState: "No launch apps selected yet.",
                            buttonTitle: "Choose launch apps",
                            delay: 0.12
                        )

                        appSection(
                            title: "Apps to quit",
                            detail: "Remove distractions when this mode starts.",
                            bundleIdentifiers: $appsToQuit,
                            emptyState: "No apps selected to quit.",
                            buttonTitle: "Choose apps to quit",
                            delay: 0.18
                        ) {
                            Text("Context Switcher may ask for Automation permission the first time it closes another app.")
                                .font(.caption)
                                .foregroundStyle(Color.white.opacity(0.64))
                        }

                        urlsSection
                            .modifier(EditAppearMotion(delay: 0.24, isVisible: isVisible))

                        behaviorSection
                            .modifier(EditAppearMotion(delay: 0.30, isVisible: isVisible))
                    }
                    .padding(24)
                }

                footer
            }
        }
        .frame(minWidth: 720, minHeight: 700)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 34, y: 18)
        .environmentObject(appCatalog)
        .preferredColorScheme(.dark)
        .onAppear {
            load()
            withAnimation(.spring(response: 0.78, dampingFraction: 0.86)) {
                isVisible = true
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: colorHex).opacity(0.26))
                    .frame(width: 70, height: 70)

                Circle()
                    .fill(Color(hex: colorHex))
                    .frame(width: 26, height: 26)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(mode == nil ? "Create a new mode" : "Refine this mode")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Shape the apps, links, timer, and sound so this mode feels consistent every time you activate it.")
                    .font(.title3)
                    .foregroundStyle(Color.white.opacity(0.72))

                HStack(spacing: 10) {
                    summaryPill(title: "\(selectedLaunchApps.count)", subtitle: "launch")
                    summaryPill(title: "\(selectedQuitApps.count)", subtitle: "quit")
                    summaryPill(title: timerMinutes == 0 ? "Off" : "\(timerMinutes)m", subtitle: "timer")
                }
                .padding(.top, 2)
            }

            Spacer()
        }
        .padding(24)
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.20, green: 0.18, blue: 0.33).opacity(0.95),
                        Color(red: 0.11, green: 0.12, blue: 0.22).opacity(0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Rectangle()
                    .fill(.ultraThinMaterial.opacity(0.65))
            }
        )
        .overlay(alignment: .bottom) {
            Divider()
                .overlay(Color.white.opacity(0.06))
        }
    }

    private var identitySection: some View {
        EditGlassSection(title: "Mode identity", subtitle: "Name the mode and choose a signature accent color.") {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mode name")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.92))

                    TextField("Deep Work", text: $name)
                        .textFieldStyle(.plain)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Color")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.92))

                    HStack(spacing: 12) {
                        ForEach(Self.palette, id: \.self) { hex in
                            colorCircle(hex)
                        }
                    }
                }
            }
        }
    }

    private var urlsSection: some View {
        EditGlassSection(title: "URLs to open", subtitle: "Open documents, dashboards, or focus playlists with the mode.") {
            UrlListEditor(items: $urlsToOpen)
        }
    }

    private var behaviorSection: some View {
        EditGlassSection(title: "Behavior", subtitle: "Decide how long the mode runs and whether it should play a cue.") {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Timer")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.white.opacity(0.92))
                        Text("Set 0 to keep the session open-ended.")
                            .font(.caption)
                            .foregroundStyle(Color.white.opacity(0.64))
                    }

                    Spacer()

                    Stepper(value: $timerMinutes, in: 0...180) {
                        Text("\(timerMinutes) minutes")
                            .foregroundStyle(.white)
                            .font(.headline.monospacedDigit())
                    }
                    .labelsHidden()

                    Text(timerMinutes == 0 ? "Off" : "\(timerMinutes)m")
                        .foregroundStyle(.white)
                        .font(.headline.monospacedDigit())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08), in: Capsule())
                }

                Toggle(isOn: $soundEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Play sound on activation")
                            .foregroundStyle(Color.white.opacity(0.92))
                        Text("Useful if you want a clear cue that the transition happened.")
                            .font(.caption)
                            .foregroundStyle(Color.white.opacity(0.64))
                    }
                }
                .toggleStyle(.switch)
            }
        }
    }

    private var footer: some View {
        HStack {
            if let mode {
                Button("Delete") {
                    store.delete(mode)
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color(red: 0.98, green: 0.70, blue: 0.74))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.06), in: Capsule())
            }

            Spacer()

            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.white.opacity(0.76))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.06), in: Capsule())

            Button("Save Mode") {
                save()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .fontWeight(.semibold)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.45, green: 0.39, blue: 0.86),
                        Color(red: 0.69, green: 0.63, blue: 0.90)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: Capsule()
            )
            .disabled(trimmedName.isEmpty)
            .opacity(trimmedName.isEmpty ? 0.55 : 1)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(.regularMaterial.opacity(0.72))
        .overlay(alignment: .top) {
            Divider()
                .overlay(Color.white.opacity(0.06))
        }
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
                .fill(Color(red: 0.53, green: 0.73, blue: 0.84).opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 28)
                .offset(x: 220, y: -220)

            Circle()
                .fill(Color(red: 0.77, green: 0.67, blue: 0.86).opacity(0.20))
                .frame(width: 360, height: 360)
                .blur(radius: 34)
                .offset(x: -240, y: 200)

            Circle()
                .fill(Color(red: 0.99, green: 0.83, blue: 0.86).opacity(0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 36)
                .offset(x: 0, y: -260)
        }
        .ignoresSafeArea()
    }

    private func appSection<Content: View>(
        title: String,
        detail: String,
        bundleIdentifiers: Binding<[String]>,
        emptyState: String,
        buttonTitle: String,
        delay: Double,
        @ViewBuilder footerContent: () -> Content = { EmptyView() }
    ) -> some View {
        EditGlassSection(title: title, subtitle: detail) {
            VStack(alignment: .leading, spacing: 12) {
                InstalledAppSelectionField(
                    bundleIdentifiers: bundleIdentifiers,
                    emptyState: emptyState,
                    buttonTitle: buttonTitle
                )
                footerContent()
            }
        }
        .modifier(EditAppearMotion(delay: delay, isVisible: isVisible))
    }

    private func summaryPill(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.64))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08), in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func colorCircle(_ hex: String) -> some View {
        Circle()
            .fill(Color(hex: hex))
            .frame(width: 34, height: 34)
            .overlay(
                Circle()
                    .strokeBorder(Color.white.opacity(colorHex == hex ? 0.92 : 0), lineWidth: 2.5)
                    .padding(-4)
            )
            .shadow(color: Color(hex: hex).opacity(0.35), radius: 12, y: 6)
            .scaleEffect(colorHex == hex ? 1.08 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.76), value: colorHex)
            .onTapGesture {
                colorHex = hex
            }
    }

    private func load() {
        guard let mode else {
            ensureURLRow()
            return
        }

        name = mode.name
        colorHex = mode.colorHex
        appsToLaunch = mode.appsToLaunch
        appsToQuit = mode.appsToQuit
        urlsToOpen = mode.urlsToOpen.isEmpty ? [""] : mode.urlsToOpen
        timerMinutes = mode.timerMinutes
        soundEnabled = mode.soundEnabled
    }

    private func save() {
        let savedMode = Mode(
            id: mode?.id ?? UUID(),
            name: trimmedName,
            colorHex: colorHex,
            appsToLaunch: appsToLaunch,
            appsToQuit: appsToQuit,
            urlsToOpen: normalized(items: urlsToOpen),
            timerMinutes: timerMinutes,
            soundEnabled: soundEnabled,
            createdAt: mode?.createdAt ?? .now
        ).sanitizedForSave()

        store.upsert(savedMode)
        dismiss()
    }

    private func normalized(items: [String]) -> [String] {
        items
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func ensureURLRow() {
        if urlsToOpen.isEmpty {
            urlsToOpen = [""]
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var selectedLaunchApps: [String] {
        normalized(items: appsToLaunch)
    }

    private var selectedQuitApps: [String] {
        normalized(items: appsToQuit)
    }

    private static let palette = [
        "#6E59CF",
        "#0F6E56",
        "#379F91",
        "#4A90E2",
        "#E7A33D",
        "#808080"
    ]
}

private struct EditGlassSection<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content

    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.66))
            }

            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 16, y: 10)
    }
}

private struct UrlListEditor: View {
    @Binding var items: [String]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, _ in
                HStack(spacing: 10) {
                    TextField(
                        "https://example.com",
                        text: Binding(
                            get: { items[index] },
                            set: { items[index] = $0 }
                        )
                    )
                    .textFieldStyle(.plain)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                    )

                    Button {
                        removeRow(at: index)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.white.opacity(0.62))
                }
            }

            Button("Add URL") {
                items.append("")
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.08), in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
            )
            .foregroundStyle(Color(red: 0.78, green: 0.83, blue: 0.98))
            .frame(maxWidth: .infinity, alignment: .leading)
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

private struct EditAppearMotion: ViewModifier {
    let delay: Double
    let isVisible: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 22)
            .scaleEffect(isVisible ? 1 : 0.985)
            .animation(
                .spring(response: 0.76, dampingFraction: 0.86).delay(delay),
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
