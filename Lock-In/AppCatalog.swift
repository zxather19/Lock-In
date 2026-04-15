import AppKit
import Combine
import SwiftUI

struct InstalledApp: Identifiable, Hashable {
    var id: String { bundleIdentifier }
    let bundleIdentifier: String
    let name: String
    let url: URL
}

@MainActor
final class AppCatalogStore: ObservableObject {
    @Published private(set) var apps: [InstalledApp] = []
    @Published private(set) var isLoading = false

    init() {
        Task {
            await loadIfNeeded()
        }
    }

    func loadIfNeeded() async {
        guard apps.isEmpty, !isLoading else { return }
        isLoading = true
        apps = await Self.discoverInstalledApps()
        isLoading = false
    }

    func appName(for bundleIdentifier: String) -> String {
        apps.first(where: { $0.bundleIdentifier == bundleIdentifier })?.name ?? bundleIdentifier
    }

    func app(for bundleIdentifier: String) -> InstalledApp? {
        apps.first(where: { $0.bundleIdentifier == bundleIdentifier })
    }

    private static func discoverInstalledApps() async -> [InstalledApp] {
        await Task.detached(priority: .userInitiated) {
            let fileManager = FileManager.default
            let roots = [
                URL(fileURLWithPath: "/Applications"),
                URL(fileURLWithPath: "/System/Applications"),
                fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
            ]

            var discovered: [String: InstalledApp] = [:]

            for root in roots where fileManager.fileExists(atPath: root.path) {
                guard let enumerator = fileManager.enumerator(
                    at: root,
                    includingPropertiesForKeys: [.isDirectoryKey, .isApplicationKey],
                    options: [.skipsHiddenFiles, .skipsPackageDescendants]
                ) else {
                    continue
                }

                while let url = enumerator.nextObject() as? URL {
                    guard url.pathExtension == "app" else { continue }
                    guard let bundle = Bundle(url: url) else { continue }
                    guard let bundleIdentifier = bundle.bundleIdentifier, !bundleIdentifier.isEmpty else { continue }

                    let displayName =
                        bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
                        bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ??
                        url.deletingPathExtension().lastPathComponent

                    discovered[bundleIdentifier] = InstalledApp(
                        bundleIdentifier: bundleIdentifier,
                        name: displayName,
                        url: url
                    )
                }
            }

            return discovered.values.sorted {
                if $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedSame {
                    return $0.bundleIdentifier < $1.bundleIdentifier
                }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }.value
    }
}

struct InstalledAppSelectionField: View {
    @EnvironmentObject private var appCatalog: AppCatalogStore

    @Binding var bundleIdentifiers: [String]

    let emptyState: String
    let buttonTitle: String

    @State private var showingPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if selectedBundleIDs.isEmpty {
                HStack(spacing: 10) {
                    LockInIconBadge(systemName: "app.badge", tint: LockInTheme.lavender)
                    Text(emptyState)
                        .font(.subheadline)
                        .foregroundStyle(LockInTheme.mutedInk)
                    Spacer()
                }
                .padding(12)
                .lockInGlass(cornerRadius: 16, opacity: 0.045)
            } else {
                VStack(spacing: 8) {
                    ForEach(selectedBundleIDs, id: \.self) { bundleID in
                        HStack(spacing: 10) {
                            appIcon(for: bundleID)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(appCatalog.appName(for: bundleID))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(LockInTheme.ink)
                                Text(bundleID)
                                    .font(.caption2)
                                    .foregroundStyle(LockInTheme.faintInk)
                                    .textSelection(.enabled)
                            }

                            Spacer()

                            Button {
                                remove(bundleID)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption.weight(.bold))
                                    .frame(width: 24, height: 24)
                                    .background(Color.white.opacity(0.08), in: Circle())
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(LockInTheme.mutedInk)
                        }
                        .padding(10)
                        .lockInGlass(cornerRadius: 16, opacity: 0.052)
                    }
                }
            }

            Button {
                showingPicker = true
            } label: {
                Label(buttonTitle, systemImage: "plus")
            }
            .buttonStyle(LockInSecondaryButtonStyle())
        }
        .sheet(isPresented: $showingPicker) {
            InstalledAppPickerSheet(
                selectedBundleIdentifiers: selectedBundleIDs,
                onSelect: { app in
                    add(app.bundleIdentifier)
                }
            )
            .environmentObject(appCatalog)
        }
    }

    @ViewBuilder
    private func appIcon(for bundleIdentifier: String) -> some View {
        if let app = appCatalog.app(for: bundleIdentifier) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: app.url.path))
                .resizable()
                .frame(width: 30, height: 30)
        } else {
            LockInIconBadge(systemName: "app", tint: LockInTheme.blue)
                .frame(width: 30, height: 30)
        }
    }

    private var selectedBundleIDs: [String] {
        bundleIdentifiers
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func add(_ bundleIdentifier: String) {
        guard !selectedBundleIDs.contains(bundleIdentifier) else { return }
        bundleIdentifiers = selectedBundleIDs + [bundleIdentifier]
    }

    private func remove(_ bundleIdentifier: String) {
        bundleIdentifiers = selectedBundleIDs.filter { $0 != bundleIdentifier }
    }
}

private struct InstalledAppPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appCatalog: AppCatalogStore

    let selectedBundleIdentifiers: [String]
    let onSelect: (InstalledApp) -> Void

    @State private var searchText = ""

    var body: some View {
        ZStack {
            LockInLiquidBackground(density: .compact)

            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 14) {
                    LockInIconBadge(systemName: "square.grid.2x2", tint: LockInTheme.cyan)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Choose apps")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(LockInTheme.ink)
                        Text("Select from the apps installed on this Mac. No bundle IDs needed.")
                            .font(.subheadline)
                            .foregroundStyle(LockInTheme.mutedInk)
                    }

                    Spacer()

                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(LockInPrimaryButtonStyle())
                }
                .padding(22)

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(LockInTheme.faintInk)
                    TextField("Search installed apps", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundStyle(LockInTheme.ink)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .lockInGlass(cornerRadius: 16, opacity: 0.07)
                .padding(.horizontal, 22)
                .padding(.bottom, 14)

                if appCatalog.isLoading && filteredApps.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                            .controlSize(.large)
                        Text("Loading installed apps...")
                            .foregroundStyle(LockInTheme.mutedInk)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredApps) { app in
                                InstalledAppPickerRow(
                                    app: app,
                                    isSelected: selectedBundleIdentifiers.contains(app.bundleIdentifier),
                                    onSelect: {
                                        onSelect(app)
                                    }
                                )
                            }

                            if filteredApps.isEmpty {
                                VStack(spacing: 10) {
                                    LockInIconBadge(systemName: "magnifyingglass", tint: LockInTheme.rose)
                                    Text("No apps found")
                                        .font(.headline)
                                        .foregroundStyle(LockInTheme.ink)
                                    Text("Try searching by app name or bundle identifier.")
                                        .font(.subheadline)
                                        .foregroundStyle(LockInTheme.mutedInk)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 42)
                            }
                        }
                        .padding(.horizontal, 22)
                        .padding(.bottom, 22)
                    }
                }
            }
        }
        .frame(minWidth: 560, minHeight: 520)
        .preferredColorScheme(.dark)
        .task {
            await appCatalog.loadIfNeeded()
        }
    }

    private var filteredApps: [InstalledApp] {
        guard !searchText.isEmpty else { return appCatalog.apps }

        return appCatalog.apps.filter { app in
            app.name.localizedCaseInsensitiveContains(searchText) ||
            app.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }
}

private struct InstalledAppPickerRow: View {
    let app: InstalledApp
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: app.url.path))
                .resizable()
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(app.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LockInTheme.ink)
                Text(app.bundleIdentifier)
                    .font(.caption2)
                    .foregroundStyle(LockInTheme.faintInk)
                    .textSelection(.enabled)
            }

            Spacer()

            if isSelected {
                Label("Added", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LockInTheme.mint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(LockInTheme.mint.opacity(0.12), in: Capsule())
            } else {
                Button("Add") {
                    onSelect()
                }
                .buttonStyle(LockInSecondaryButtonStyle())
            }
        }
        .padding(12)
        .lockInGlass(cornerRadius: 18, opacity: 0.06, highlighted: isHovered || isSelected)
        .scaleEffect(isHovered ? 1.006 : 1)
        .animation(.easeOut(duration: 0.16), value: isHovered)
        .onHover { isHovered = $0 }
    }
}
