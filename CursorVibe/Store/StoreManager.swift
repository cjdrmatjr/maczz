import Foundation
import AppKit
import Combine

/// Manages the cursor theme marketplace, purchases, and subscriptions.
@MainActor
final class StoreManager: ObservableObject {

    @Published var availableThemes: [StoreTheme] = []
    @Published var installedThemes: [InstalledTheme] = []
    @Published var subscription: UserSubscription = .empty
    @Published var isLoading = false
    @Published var errorMessage: String?

    static let shared = StoreManager()

    private let appSupportURL: URL
    private let packsURL: URL
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private init() {
        let fm = FileManager.default
        appSupportURL = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("CursorVibe")
        packsURL = appSupportURL.appendingPathComponent("Packs")

        encoder.outputFormatting = .prettyPrinted
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601

        try? fm.createDirectory(at: packsURL, withIntermediateDirectories: true)

        loadInstalledThemes()
        loadSubscription()
        loadStoreCatalog()
        ensureDefaultThemeInstalled()
    }

    // MARK: - Store catalog

    func loadStoreCatalog() {
        availableThemes = StoreTheme.sampleThemes
    }

    func themes(for collection: String) -> [StoreTheme] {
        switch collection {
        case "free": return availableThemes.filter { $0.price.type == .free }
        case "premium": return availableThemes.filter { $0.price.type == .premium || $0.price.type == .premiumPlus }
        case "animated": return availableThemes.filter { $0.isAnimated }
        default: return availableThemes
        }
    }

    func searchThemes(query: String) -> [StoreTheme] {
        guard !query.isEmpty else { return availableThemes }
        let lower = query.lowercased()
        return availableThemes.filter {
            $0.name.lowercased().contains(lower) ||
            $0.author.lowercased().contains(lower) ||
            $0.tags.contains(where: { $0.lowercased().contains(lower) })
        }
    }

    // MARK: - Default theme

    private func ensureDefaultThemeInstalled() {
        let defaultId = "builtin-default"
        if !installedThemes.contains(where: { $0.id == defaultId }) {
            let defaultDir = appSupportURL.appendingPathComponent("Cursors/default")
            try? FileManager.default.createDirectory(at: defaultDir, withIntermediateDirectories: true)

            // Generate cursor images using the proper renderer
            CursorRenderer.generateSystemCursorSet(in: defaultDir)

            let installed = InstalledTheme(
                id: defaultId,
                storeThemeId: nil,
                name: "System Default",
                localPath: defaultDir,
                installedDate: Date(),
                lastUsedDate: nil,
                isActive: true,
                cursorCount: CursorRole.allCases.count
            )
            installedThemes.insert(installed, at: 0)
            saveInstalledThemes()

            // Auto-activate default theme
            activateTheme(defaultId)
        }
    }

    // MARK: - Purchase / Subscribe

    func purchaseTheme(_ theme: StoreTheme) async -> Bool {
        guard theme.price.type == .oneTime else { return false }
        isLoading = true
        try? await Task.sleep(nanoseconds: 800_000_000)
        isLoading = false

        var sub = subscription
        sub = UserSubscription(
            tier: sub.tier, isActive: sub.isActive, expiresAt: sub.expiresAt,
            purchasedThemes: sub.purchasedThemes + [theme.id],
            activeThemeId: sub.activeThemeId
        )
        subscription = sub
        saveSubscription()
        return true
    }

    func subscribe(tier: StoreTheme.Pricing.SubscriptionTier) async -> Bool {
        isLoading = true
        try? await Task.sleep(nanoseconds: 800_000_000)
        isLoading = false
        subscription = UserSubscription(
            tier: tier, isActive: true,
            expiresAt: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
            purchasedThemes: subscription.purchasedThemes,
            activeThemeId: subscription.activeThemeId
        )
        saveSubscription()
        return true
    }

    func canAccess(_ theme: StoreTheme) -> Bool {
        switch theme.price.type {
        case .free: return true
        case .oneTime: return subscription.purchasedThemes.contains(theme.id)
        case .premium: return subscription.isActive && (subscription.tier == .basic || subscription.tier == .pro)
        case .premiumPlus: return subscription.isActive && subscription.tier == .pro
        }
    }

    // MARK: - Install / Download

    func downloadAndInstall(_ theme: StoreTheme) async -> Bool {
        guard canAccess(theme) else { return false }
        isLoading = true
        defer { isLoading = false }

        let themeDir = packsURL.appendingPathComponent(theme.id)
        do {
            try FileManager.default.createDirectory(at: themeDir, withIntermediateDirectories: true)

            let manifest = CursorTheme(
                id: theme.id, name: theme.name, author: theme.author,
                description: theme.description, version: theme.version,
                previewImage: "preview.png",
                cursors: CursorRole.allCases.map { role in
                    CursorTheme.CursorDefinition(
                        id: role.rawValue, name: role.rawValue,
                        imageFile: "\(role.rawValue).png", animatedFile: nil,
                        hotspot: .init(x: 0.25, y: 0.25), scale: 1.0, fps: 0
                    )
                },
                tags: theme.tags,
                price: theme.price.type == .free ? nil : .init(
                    type: theme.price.type == .oneTime ? .oneTime : .subscription,
                    amount: theme.price.amount, currency: theme.price.currency
                ),
                isBuiltIn: false
            )
            let data = try encoder.encode(manifest)
            try data.write(to: themeDir.appendingPathComponent("manifest.json"))

            // Generate themed cursors using CursorRenderer
            CursorRenderer.generateSystemCursorSet(in: themeDir)

            let installed = InstalledTheme(
                id: theme.id, storeThemeId: theme.id, name: theme.name,
                localPath: themeDir, installedDate: Date(), lastUsedDate: nil,
                isActive: false, cursorCount: theme.cursorCount
            )
            installedThemes.append(installed)
            saveInstalledThemes()
            return true
        } catch {
            errorMessage = "Installation failed: \(error.localizedDescription)"
            return false
        }
    }

    func activateTheme(_ themeId: String) {
        for i in installedThemes.indices {
            let wasActive = installedThemes[i].isActive
            let isActive = (installedThemes[i].id == themeId)
            if wasActive != isActive {
                installedThemes[i] = InstalledTheme(
                    id: installedThemes[i].id,
                    storeThemeId: installedThemes[i].storeThemeId,
                    name: installedThemes[i].name,
                    localPath: installedThemes[i].localPath,
                    installedDate: installedThemes[i].installedDate,
                    lastUsedDate: isActive ? Date() : installedThemes[i].lastUsedDate,
                    isActive: isActive,
                    cursorCount: installedThemes[i].cursorCount
                )
            }
        }
        saveInstalledThemes()

        if let active = installedThemes.first(where: { $0.id == themeId }) {
            CursorEngine.shared.loadTheme(from: active.localPath)
            CursorEngine.shared.isEnabled = true
        }
    }

    func uninstallTheme(_ themeId: String) {
        guard themeId != "builtin-default" else { return } // Can't uninstall default
        guard let theme = installedThemes.first(where: { $0.id == themeId }) else { return }
        try? FileManager.default.removeItem(at: theme.localPath)
        installedThemes.removeAll { $0.id == themeId }
        saveInstalledThemes()

        // If the uninstalled theme was active, switch to default
        if theme.isActive {
            activateTheme("builtin-default")
        }
    }

    // MARK: - Persistence

    private func saveInstalledThemes() {
        guard let data = try? encoder.encode(installedThemes) else { return }
        try? data.write(to: appSupportURL.appendingPathComponent("installed.json"))
    }

    private func loadInstalledThemes() {
        let url = appSupportURL.appendingPathComponent("installed.json")
        guard let data = try? Data(contentsOf: url) else { return }
        installedThemes = (try? decoder.decode([InstalledTheme].self, from: data)) ?? []
    }

    private func saveSubscription() {
        guard let data = try? encoder.encode(subscription) else { return }
        try? data.write(to: appSupportURL.appendingPathComponent("subscription.json"))
    }

    private func loadSubscription() {
        let url = appSupportURL.appendingPathComponent("subscription.json")
        guard let data = try? Data(contentsOf: url) else { return }
        subscription = (try? decoder.decode(UserSubscription.self, from: data)) ?? .empty
    }
}
