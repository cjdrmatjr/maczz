import Foundation

// MARK: - Store / Marketplace Models

/// Represents a cursor theme in the marketplace
struct StoreTheme: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let author: String
    let authorId: String
    let description: String
    let previewImages: [String]       // URLs to preview images
    let downloadURL: String
    let version: String
    let tags: [String]
    let price: Pricing
    let rating: Double
    let downloadCount: Int
    let createdAt: Date
    let updatedAt: Date
    let fileSize: Int                 // bytes
    let isAnimated: Bool
    let cursorCount: Int

    struct Pricing: Codable, Hashable {
        let type: PricingType
        let amount: Double
        let currency: String
        let subscriptionTier: SubscriptionTier?

        enum PricingType: String, Codable {
            case free
            case oneTime          // one-time purchase
            case premium          // requires subscription
            case premiumPlus      // requires higher tier
        }

        enum SubscriptionTier: String, Codable {
            case basic            // $2.99/mo - access to all free + basic themes
            case pro              // $5.99/mo - all themes + exclusive pro packs
        }
    }
}

/// User's purchase/subscription state
struct UserSubscription: Codable {
    let tier: StoreTheme.Pricing.SubscriptionTier?
    let isActive: Bool
    let expiresAt: Date?
    let purchasedThemes: [String]    // theme IDs
    let activeThemeId: String?

    static let empty = UserSubscription(
        tier: nil,
        isActive: false,
        expiresAt: nil,
        purchasedThemes: [],
        activeThemeId: nil
    )
}

/// Featured collections shown in the store
struct StoreCollection: Codable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let themeIds: [String]
    let sortOrder: Int
}

/// User's locally installed themes
struct InstalledTheme: Codable, Identifiable {
    let id: String
    let storeThemeId: String?       // nil for custom/uploaded themes
    let name: String
    let localPath: URL
    let installedDate: Date
    let lastUsedDate: Date?
    var isActive: Bool
    let cursorCount: Int
}

// MARK: - Sample store data for development

extension StoreTheme {
    static let sampleThemes: [StoreTheme] = [
        StoreTheme(
            id: "neon-pulse",
            name: "Neon Pulse",
            author: "CursorVibe Studio",
            authorId: "cv-studio",
            description: "Vibrant animated neon cursors that pulse with color. Perfect for dark mode enthusiasts.",
            previewImages: [],
            downloadURL: "",
            version: "1.2.0",
            tags: ["neon", "animated", "dark", "glow"],
            price: .init(type: .premium, amount: 0, currency: "USD", subscriptionTier: .basic),
            rating: 4.8,
            downloadCount: 12400,
            createdAt: Date(),
            updatedAt: Date(),
            fileSize: 2_400_000,
            isAnimated: true,
            cursorCount: 14
        ),
        StoreTheme(
            id: "minimal-white",
            name: "Minimal White",
            author: "DesignLab",
            authorId: "designlab",
            description: "Clean, minimal white cursors with subtle shadows. A perfect match for light themes.",
            previewImages: [],
            downloadURL: "",
            version: "2.0.0",
            tags: ["minimal", "clean", "light", "white"],
            price: .init(type: .free, amount: 0, currency: "USD", subscriptionTier: nil),
            rating: 4.5,
            downloadCount: 34200,
            createdAt: Date(),
            updatedAt: Date(),
            fileSize: 890_000,
            isAnimated: false,
            cursorCount: 14
        ),
        StoreTheme(
            id: "cat-paws",
            name: "Cat Paws",
            author: "KawaiiCursor",
            authorId: "kawaii",
            description: "Adorable cat paw cursors! Each cursor is a different colored paw with tiny toe beans.",
            previewImages: [],
            downloadURL: "",
            version: "1.0.0",
            tags: ["cute", "cat", "animal", "kawaii"],
            price: .init(type: .oneTime, amount: 1.99, currency: "USD", subscriptionTier: nil),
            rating: 4.9,
            downloadCount: 8700,
            createdAt: Date(),
            updatedAt: Date(),
            fileSize: 1_200_000,
            isAnimated: false,
            cursorCount: 14
        ),
        StoreTheme(
            id: "retro-pixel",
            name: "Retro Pixel",
            author: "8BitArtisan",
            authorId: "8bit",
            description: "Nostalgic 16-bit pixel art cursors. Includes animated variants with classic pixel animations.",
            previewImages: [],
            downloadURL: "",
            version: "1.3.0",
            tags: ["retro", "pixel", "8bit", "gaming"],
            price: .init(type: .premium, amount: 0, currency: "USD", subscriptionTier: .pro),
            rating: 4.7,
            downloadCount: 15600,
            createdAt: Date(),
            updatedAt: Date(),
            fileSize: 3_100_000,
            isAnimated: true,
            cursorCount: 14
        ),
    ]
}
