import SwiftUI

/// Compact menu bar popover for quick cursor management.
struct MenuBarView: View {
    @EnvironmentObject var engine: CursorEngine
    @EnvironmentObject var store: StoreManager

    @State private var showStore = false
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            toggleSection
            Divider()
            installedThemesSection
            Divider()
            quickActions
        }
        .frame(width: 340, height: 460)
        .sheet(isPresented: $showStore) { StoreView().environmentObject(engine).environmentObject(store) }
        .sheet(isPresented: $showSettings) { SettingsView().environmentObject(engine).environmentObject(store) }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 28, height: 28)
                Image(systemName: "cursorarrow.motionlines")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Text("CursorVibe")
                .font(.system(size: 14, weight: .bold))
            Spacer()
            statusBadge
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var statusBadge: some View {
        if engine.isEnabled {
            Label("Active", systemImage: "checkmark.circle.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.green.opacity(0.12))
                .clipShape(Capsule())
        } else {
            Label("Off", systemImage: "moon.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.gray.opacity(0.12))
                .clipShape(Capsule())
        }
    }

    // MARK: - Toggle

    private var toggleSection: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: engine.isEnabled ? "cursorarrow.click.2.fill" : "cursorarrow.click.2")
                    .font(.system(size: 16))
                    .foregroundStyle(engine.isEnabled ? .blue : .secondary)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Custom Cursor")
                        .font(.system(size: 13, weight: .medium))
                    Text(engine.isEnabled ? "Your cursor is customized" : "Using system cursor")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: $engine.isEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
            if engine.isEnabled, let theme = engine.currentTheme {
                HStack(spacing: 6) {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.purple)
                    Text("Theme: \(theme.name)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.purple)
                    Spacer()
                }
                .padding(.leading, 32)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(engine.isEnabled ? Color.blue.opacity(0.04) : Color.clear)
    }

    // MARK: - Installed themes

    private var installedThemesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Installed Themes")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
                Text("\(store.installedThemes.count)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            if store.installedThemes.isEmpty {
                emptyThemesView
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(store.installedThemes) { theme in
                            themeRow(theme)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
    }

    private var emptyThemesView: some View {
        VStack(spacing: 6) {
            Image(systemName: "square.and.arrow.down.on.square")
                .font(.system(size: 24))
                .foregroundStyle(.tertiary)
            Text("No themes installed")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Visit the store to browse cursor themes")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private func themeRow(_ theme: InstalledTheme) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(theme.isActive
                          ? LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                          : LinearGradient(colors: [.gray.opacity(0.08), .gray.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 36, height: 36)
                Image(systemName: theme.isActive ? "cursorarrow.click.2.fill" : "cursorarrow.motionlines")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.isActive ? .blue : .secondary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(theme.name)
                    .font(.system(size: 12, weight: theme.isActive ? .semibold : .regular))
                    .lineLimit(1)
                Text("\(theme.cursorCount) cursors")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if theme.isActive {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(theme.isActive ? Color.blue.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            store.activateTheme(theme.id)
        }
    }

    // MARK: - Quick actions

    private var quickActions: some View {
        HStack(spacing: 8) {
            Button {
                openWindow(id: "store")
            } label: {
                Label("Store", systemImage: "bag.fill")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(.blue)

            Button {
                openWindow(id: "settings")
            } label: {
                Label("Settings", systemImage: "gear")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Spacer()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .font(.system(size: 12))
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func openWindow(id: String) {
        // SwiftUI window IDs
        if let window = NSApplication.shared.windows.first(where: { $0.title == windowTitle(for: id) }) {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func windowTitle(for id: String) -> String {
        switch id {
        case "store": return "Cursor Store"
        case "settings": return "CursorVibe Settings"
        default: return ""
        }
    }
}
