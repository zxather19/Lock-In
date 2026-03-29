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

                for case let url as URL in enumerator {
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
                Text(emptyState)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(selectedBundleIDs, id: \.self) { bundleID in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(appCatalog.appName(for: bundleID))
                                .font(.subheadline.weight(.medium))
                            Text(bundleID)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }

                        Spacer()

                        Button {
                            remove(bundleID)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Button(buttonTitle) {
                showingPicker = true
            }
            .buttonStyle(.link)
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
        NavigationStack {
            Group {
                if appCatalog.isLoading && filteredApps.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading installed apps...")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredApps) { app in
                        HStack(spacing: 12) {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: app.url.path))
                                .resizable()
                                .frame(width: 28, height: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.name)
                                Text(app.bundleIdentifier)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedBundleIdentifiers.contains(app.bundleIdentifier) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Button("Add") {
                                    onSelect(app)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .searchable(text: $searchText, prompt: "Search installed apps")
                }
            }
            .navigationTitle("Choose Apps")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 560, minHeight: 520)
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
