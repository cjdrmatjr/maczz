import Cocoa
import Combine

/// Tracks mouse movement globally, replaces system cursor with transparent one.
final class CursorTracker {

    enum CursorState {
        case normal
        case pointing
        case text
        case dragging
        case resize
        case copy
        case forbidden
        case wait
    }

    private var moveMonitor: Any?
    private var downMonitor: Any?
    private var upMonitor: Any?
    private var flagsMonitor: Any?

    private var isTracking = false

    var onMove: ((NSPoint) -> Void)?
    var onStateChange: ((CursorState) -> Void)?
    var onMouseDown: ((NSPoint) -> Void)?
    var onMouseUp: ((NSPoint) -> Void)?

    private(set) var currentState: CursorState = .normal {
        didSet {
            if currentState != oldValue {
                onStateChange?(currentState)
            }
        }
    }

    /// Transparent cursor to replace the system cursor
    private lazy var invisibleCursor: NSCursor = {
        let size = NSSize(width: 1, height: 1)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.clear.set()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        return NSCursor(image: image, hotSpot: .zero)
    }()

    // MARK: - Start/Stop

    func start() {
        guard !isTracking else { return }
        isTracking = true
        applyInvisibleCursor()
        startMonitoring()
    }

    func stop() {
        guard isTracking else { return }
        isTracking = false
        stopMonitoring()
        restoreSystemCursor()
    }

    // MARK: - Cursor hiding

    private func applyInvisibleCursor() {
        invisibleCursor.set()
        // Also push on the cursor stack so it persists across app focus changes
        NSCursor.pop()
        invisibleCursor.set()
    }

    private func restoreSystemCursor() {
        NSCursor.arrow.set()
    }

    /// Re-apply invisible cursor (call when cursor might have reset)
    func reinforceInvisibleCursor() {
        guard isTracking else { return }
        invisibleCursor.set()
    }

    // MARK: - Event monitoring

    private func startMonitoring() {
        moveMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]) {
            [weak self] event in
            self?.handleMouseMoved(event)
        }

        downMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) {
            [weak self] event in
            guard let self = self else { return }
            self.currentState = .dragging
            self.onMouseDown?(NSEvent.mouseLocation)
        }

        upMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp, .rightMouseUp, .otherMouseUp]) {
            [weak self] event in
            guard let self = self else { return }
            self.currentState = .normal
            self.onMouseUp?(NSEvent.mouseLocation)
        }

        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) {
            [weak self] event in
            self?.handleFlagsChanged(event)
        }
    }

    private func stopMonitoring() {
        [moveMonitor, downMonitor, upMonitor, flagsMonitor].compactMap { $0 }.forEach { NSEvent.removeMonitor($0) }
        moveMonitor = nil
        downMonitor = nil
        upMonitor = nil
        flagsMonitor = nil
    }

    // MARK: - Event handling

    private func handleMouseMoved(_ event: NSEvent) {
        // NSEvent.mouseLocation: bottom-left origin (native macOS coordinate system)
        let point = NSEvent.mouseLocation
        onMove?(point)
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let flags = event.modifierFlags
        if flags.contains(.option) && flags.contains(.command) {
            currentState = .copy
        } else if flags.contains(.option) {
            currentState = .resize
        } else if currentState == .copy || currentState == .resize {
            currentState = .normal
        }
    }
}
