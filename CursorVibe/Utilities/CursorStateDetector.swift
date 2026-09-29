import Cocoa

/// Detects the appropriate cursor state based on the UI element under the mouse pointer.
/// Uses Accessibility APIs to determine what kind of cursor should be shown.
final class CursorStateDetector {

    private var lastDetectedRole: CursorRole = .defaultCursor
    private var detectionTimer: Timer?

    /// Start periodic detection of cursor state from UI elements under mouse
    func startDetection(interval: TimeInterval = 0.1, onChange: @escaping (CursorRole) -> Void) {
        detectionTimer?.invalidate()
        detectionTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let role = self.detectCurrentRole()
            if role != self.lastDetectedRole {
                self.lastDetectedRole = role
                onChange(role)
            }
        }
    }

    func stopDetection() {
        detectionTimer?.invalidate()
        detectionTimer = nil
    }

    /// Detect the cursor role based on the element under the mouse
    private func detectCurrentRole() -> CursorRole {
        let mouseLocation = NSEvent.mouseLocation
        // Convert to CG coordinates (top-left origin)
        guard let screen = NSScreen.main else { return .defaultCursor }
        let cgPoint = CGPoint(
            x: mouseLocation.x,
            y: screen.frame.height - mouseLocation.y
        )

        // Get the accessibility element under the mouse
        let systemWide = AXUIElementCreateSystemWide()
        var element: AXUIElement?
        let result = AXUIElementCopyElementAtPosition(systemWide, Float(cgPoint.x), Float(cgPoint.y), &element)

        guard result == .success, let axElement = element else {
            return .defaultCursor
        }

        // Check the role of the element
        var roleValue: AnyObject?
        AXUIElementCopyAttributeValue(axElement, kAXRoleAttribute as CFString, &roleValue)

        if let role = roleValue as? String {
            switch role {
            case kAXStaticTextRole, kAXTextAreaRole, kAXTextFieldRole:
                return .text
            case kAXButtonRole, "AXLink":
                return .pointer
            case kAXMenuBarRole, kAXMenuBarItemRole:
                return .pointer
            case kAXSliderRole:
                return .resizeNS
            default:
                break
            }
        }

        // Check if the element is a URL in a web view
        var subrole: AnyObject?
        AXUIElementCopyAttributeValue(axElement, kAXSubroleAttribute as CFString, &subrole)
        if let sub = subrole as? String, sub == "AXContentGroup" {
            // In web content, check for links via AXURL
            var urlValue: AnyObject?
            AXUIElementCopyAttributeValue(axElement, kAXURLAttribute as CFString, &urlValue)
            if urlValue != nil {
                return .pointer
            }
        }

        // Check parent elements for context
        var parent: AnyObject?
        AXUIElementCopyAttributeValue(axElement, kAXParentAttribute as CFString, &parent)
        if let parentElement = parent as! AXUIElement? {
            var parentRole: AnyObject?
            AXUIElementCopyAttributeValue(parentElement, kAXRoleAttribute as CFString, &parentRole)
            if let pr = parentRole as? String {
                if pr == kAXScrollAreaRole || pr == kAXTableRole {
                    return .defaultCursor
                }
            }
        }

        return .defaultCursor
    }

    /// Get the system cursor that would normally be shown at the current position
    /// This uses NSCursor.current to see what the system would display
    func detectSystemCursor() -> NSCursor {
        return NSCursor.current
    }
}
