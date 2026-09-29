import Cocoa

/// Transparent overlay window that renders custom cursors on top of everything.
/// Uses bottom-left origin coordinate system (native macOS).
final class CursorOverlay: NSWindowController {

    private var cursorImageView: NSImageView!

    convenience init() {
        guard let screen = NSScreen.main else { fatalError("No screen") }

        let window = NSWindow(
            contentRect: screen.frame,        // origin (0,0) bottom-left, covers full screen
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true       // click-through
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.isReleasedWhenClosed = false

        self.init(window: window)
        setupCursorView()
    }

    private func setupCursorView() {
        guard let contentView = window?.contentView else { return }
        cursorImageView = NSImageView(frame: NSRect(x: 0, y: 0, width: 32, height: 32))
        cursorImageView.imageScaling = .scaleProportionallyUpOrDown
        cursorImageView.isEditable = false
        contentView.addSubview(cursorImageView)
    }

    // MARK: - Show/Hide

    func showOverlay() {
        window?.orderFrontRegardless()
    }

    func hideOverlay() {
        window?.orderOut(nil)
    }

    // MARK: - Position (bottom-left origin throughout)

    /// Update cursor position. point is in NSEvent.mouseLocation coordinates (bottom-left origin).
    func updatePosition(_ point: NSPoint) {
        guard self.window != nil else { return }

        // Both point and window use bottom-left origin — direct use
        let hotspot = currentHotspot
        let size = cursorImageView.frame.size

        // Position so the hotspot aligns with the mouse point
        // In bottom-left origin: image bottom-left = point - hotspot-from-bottom
        let hotspotFromBottom = size.height - hotspot.y
        cursorImageView.frame.origin = CGPoint(
            x: point.x - hotspot.x,
            y: point.y - hotspotFromBottom
        )
    }

    // MARK: - Cursor image

    private var currentHotspot: NSPoint = NSPoint(x: 4, y: 4)

    func setCursorImage(_ image: NSImage?, hotspot: NSPoint = NSPoint(x: 4, y: 4)) {
        cursorImageView.image = image
        currentHotspot = hotspot
        if let image = image {
            cursorImageView.frame.size = image.size
        }
    }

    func setCursorAnimated(_ frames: [NSImage], fps: Double, hotspot: NSPoint) {
        currentHotspot = hotspot
        guard !frames.isEmpty else { return }
        cursorImageView.frame.size = frames[0].size
        cursorImageView.image = frames[0]

        var frameIndex = 0
        let interval = 1.0 / max(fps, 1.0)
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self = self, self.window?.isVisible == true else {
                timer.invalidate()
                return
            }
            frameIndex = (frameIndex + 1) % frames.count
            self.cursorImageView.image = frames[frameIndex]
        }
    }
}
