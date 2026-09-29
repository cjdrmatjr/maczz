import Foundation

/// Represents a cursor theme pack that can be loaded, previewed, and applied.
struct CursorTheme: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let author: String
    let description: String
    let version: String
    let previewImage: String          // filename in pack
    let cursors: [CursorDefinition]
    let tags: [String]
    let price: Price?
    let isBuiltIn: Bool

    struct CursorDefinition: Codable, Identifiable, Hashable {
        let id: String                // e.g., "default", "pointer", "text", "wait"
        let name: String
        let imageFile: String         // static image filename
        let animatedFile: String?     // animated file (gif/apng), nil if static
        let hotspot: Hotspot
        let scale: Double             // 1.0 = natural size
        let fps: Double               // animation FPS, 0 = static

        struct Hotspot: Codable, Hashable {
            let x: Double   // 0.0 - 1.0 relative to image size
            let y: Double
        }
    }

    struct Price: Codable, Hashable {
        let type: PriceType
        let amount: Double
        let currency: String

        enum PriceType: String, Codable {
            case free
            case oneTime
            case subscription
        }
    }
}

/// Cursor state types matching system cursor roles
enum CursorRole: String, CaseIterable {
    case defaultCursor = "default"
    case pointer = "pointer"         // hand cursor
    case text = "text"               // I-beam
    case crosshair = "crosshair"
    case move = "move"
    case resizeNS = "resize-ns"      // up-down
    case resizeEW = "resize-ew"      // left-right
    case resizeNESW = "resize-nesw"
    case resizeNWSE = "resize-nwse"
    case notAllowed = "not-allowed"
    case wait = "wait"
    case copy = "copy"
    case drag = "drag"
    case grab = "grab"

    var systemEquivalent: String {
        switch self {
        case .defaultCursor: return "arrow"
        case .pointer: return "pointingHand"
        case .text: return "IBeam"
        case .crosshair: return "crosshair"
        case .move: return "move"
        case .resizeNS: return "resizeUpDown"
        case .resizeEW: return "resizeLeftRight"
        case .resizeNESW: return "resizeUpDown" // approximate
        case .resizeNWSE: return "resizeLeftRight" // approximate
        case .notAllowed: return "operationNotAllowed"
        case .wait: return "wait"
        case .copy: return "copy"
        case .drag, .grab: return "openHand"
        }
    }
}

/// A cursor pack installed on disk
struct InstalledCursorPack: Codable, Identifiable {
    let id: String
    let theme: CursorTheme
    let localPath: URL
    let installedDate: Date
    var isActive: Bool
}

// MARK: - Built-in default theme

extension CursorTheme {
    static let defaultTheme = CursorTheme(
        id: "builtin-default",
        name: "System Default",
        author: "CursorVibe",
        description: "Extracted from macOS system cursors",
        version: "1.0.0",
        previewImage: "preview.png",
        cursors: CursorRole.allCases.map { role in
            CursorDefinition(
                id: role.rawValue,
                name: role.rawValue,
                imageFile: "\(role.rawValue).png",
                animatedFile: nil,
                hotspot: .init(x: 0.25, y: 0.25),
                scale: 1.0,
                fps: 0
            )
        },
        tags: ["default", "clean", "modern"],
        price: nil,
        isBuiltIn: true
    )
}
