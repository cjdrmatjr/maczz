import SwiftUI

/// App settings for cursor customization and behavior.
struct SettingsView: View {
    @EnvironmentObject var engine: CursorEngine
    @EnvironmentObject var store: StoreManager

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gear") }
            cursorTab
                .tabItem { Label("Cursor", systemImage: "cursorarrow.motionlines") }
            effectsTab
                .tabItem { Label("Effects", systemImage: "sparkles") }
            subscriptionTab
                .tabItem { Label("Subscription", systemImage: "crown") }
            aboutTab
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 520, height: 380)
    }

    // MARK: - General

    private var generalTab: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: "cursorarrow.click.2")
                        .foregroundStyle(.blue)
                        .frame(width: 20)
                    Text("Enable Custom Cursor")
                    Spacer()
                    Toggle("", isOn: $engine.isEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                HStack {
                    Image(systemName: "power")
                        .foregroundStyle(.orange)
                        .frame(width: 20)
                    Text("Launch at Login")
                    Spacer()
                    Toggle("", isOn: .constant(true))
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            } header: {
                Text("General")
            }

            Section {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    Text("Status")
                    Spacer()
                    if engine.isEnabled {
                        Label("Active", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.system(size: 12, weight: .medium))
                    } else {
                        Label("Inactive", systemImage: "moon.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 12))
                    }
                }
                if let theme = engine.currentTheme {
                    HStack {
                        Image(systemName: "paintpalette")
                            .foregroundStyle(.purple)
                            .frame(width: 20)
                        Text("Current Theme")
                        Spacer()
                        Text(theme.name)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Status")
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .padding()
    }

    // MARK: - Cursor

    private var cursorTab: some View {
        Form {
            Section {
                HStack {
                    Text("Scale")
                        .frame(width: 60, alignment: .leading)
                    Slider(value: $engine.cursorScale, in: 0.5...3.0, step: 0.1)
                    Text(String(format: "%.1fx", engine.cursorScale))
                        .monospacedDigit()
                        .frame(width: 36, alignment: .trailing)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Presets")
                        .frame(width: 60, alignment: .leading)
                    ForEach([0.75, 1.0, 1.5, 2.0], id: \.self) { scale in
                        Button(String(format: "%.2fx", scale)) {
                            engine.cursorScale = scale
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(engine.cursorScale == scale ? .blue : .secondary)
                    }
                }
            } header: {
                Text("Appearance")
            }

            Section {
                if let theme = engine.currentTheme {
                    LabeledContent("Name", value: theme.name)
                    LabeledContent("Author", value: theme.author)
                    LabeledContent("Version", value: theme.version)
                    LabeledContent("Cursors", value: "\(theme.cursors.count)")
                } else {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                        Text("No theme loaded")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Current Theme")
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .padding()
    }

    // MARK: - Effects

    private var effectsTab: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.yellow)
                        .frame(width: 20)
                    Text("Cursor Trail")
                    Spacer()
                    Toggle("", isOn: $engine.trailEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                if engine.trailEnabled {
                    Text("A smooth trail follows your cursor as it moves across the screen.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 28)
                }
            } header: {
                Text("Trail Effect")
            } footer: {
                Text("Trail creates a smooth afterimage that follows your cursor.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Section {
                HStack {
                    Image(systemName: "cursorarrow.click.badge.clock")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    Text("Click Ripple")
                    Spacer()
                    Text("Coming Soon")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Capsule())
                }
                HStack {
                    Image(systemName: "wand.and.stars")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    Text("Hover Glow")
                    Spacer()
                    Text("Coming Soon")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Capsule())
                }
            } header: {
                Text("More Effects")
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .padding()
    }

    // MARK: - Subscription

    private var subscriptionTab: some View {
        VStack(spacing: 20) {
            Spacer()

            if store.subscription.isActive {
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.yellow)
                Text("Premium Active")
                    .font(.title3.bold())
                Text("\(store.subscription.tier?.rawValue.capitalized ?? "Basic") Plan")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let expires = store.subscription.expiresAt {
                    Text("Renews \(expires.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("\(store.subscription.purchasedThemes.count) themes purchased")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                Image(systemName: "crown")
                    .font(.system(size: 40))
                    .foregroundStyle(.tertiary)
                Text("Free Tier")
                    .font(.title3.bold())
                Text("Upgrade to unlock premium cursor themes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("View Plans") { }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - About

    private var aboutTab: some View {
        VStack(spacing: 12) {
            Spacer()
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 56)
                Image(systemName: "cursorarrow.motionlines")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            }
            Text("CursorVibe")
                .font(.title.bold())
            Text("Version 1.0.0")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Beautiful cursors for macOS.\nAutomatic. Customizable. Yours.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            Text("© 2026 CursorVibe")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
}
