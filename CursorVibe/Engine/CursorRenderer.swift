import Cocoa

/// Extracts real macOS system cursor images and renders them to disk.
final class CursorRenderer {

    /// Generate a set using actual macOS system cursor images.
    static func generateSystemCursorSet(in directory: URL) {
        let cursors: [(CursorRole, NSCursor)] = [
            (.defaultCursor, .arrow),
            (.pointer,       .pointingHand),
            (.text,          .iBeam),
            (.crosshair,     .crosshair),
            (.move,          .arrow),
            (.drag,          .closedHand),
            (.grab,          .openHand),
            (.notAllowed,    .operationNotAllowed),
            (.wait,          .arrow),
            (.copy,          .dragCopy),
            (.resizeNS,      .resizeUpDown),
            (.resizeEW,      .resizeLeftRight),
            (.resizeNESW,    .arrow),  // macOS doesn't expose these directly
            (.resizeNWSE,    .arrow),  // fall back to arrow
        ]

        let manifest = CursorTheme(
            id: "builtin-default",
            name: "System Default",
            author: "CursorVibe",
            description: "Extracted from macOS system cursors",
            version: "1.0.0",
            previewImage: "preview.png",
            cursors: cursors.map { (role, cursor) in
                CursorTheme.CursorDefinition(
                    id: role.rawValue,
                    name: role.rawValue,
                    imageFile: "\(role.rawValue).png",
                    animatedFile: nil,
                    hotspot: CursorRenderer.normalizedHotspot(cursor),
                    scale: 1.0,
                    fps: 0
                )
            },
            tags: ["default", "system", "macOS"],
            price: nil,
            isBuiltIn: true
        )

        for (role, cursor) in cursors {
            if let image = renderCursorToImage(cursor) {
                let url = directory.appendingPathComponent("\(role.rawValue).png")
                savePNG(image, to: url)
            }
        }

        if let data = try? JSONEncoder().encode(manifest) {
            try? data.write(to: directory.appendingPathComponent("manifest.json"))
        }
    }

    // MARK: - Render a NSCursor to NSImage

    private static func renderCursorToImage(_ cursor: NSCursor) -> NSImage? {
        let size = cursor.image.size
        guard size.width > 0, size.height > 0 else { return nil }

        let image = NSImage(size: size)
        image.lockFocus()
        // Draw the cursor image at origin
        cursor.image.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .sourceOver, fraction: 1.0)
        image.unlockFocus()
        return image
    }

    /// Get normalized hotspot (0...1) for a cursor
    private static func normalizedHotspot(_ cursor: NSCursor) -> CursorTheme.CursorDefinition.Hotspot {
        let hs = cursor.hotSpot
        let size = cursor.image.size
        guard size.width > 0, size.height > 0 else {
            return .init(x: 0.25, y: 0.25)
        }
        return .init(x: Double(hs.x / size.width), y: Double(hs.y / size.height))
    }

    // MARK: - Helpers

    private static func savePNG(_ image: NSImage, to url: URL) {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return }
        try? png.write(to: url)
    }
}
