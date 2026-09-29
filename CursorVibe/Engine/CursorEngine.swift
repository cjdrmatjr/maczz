import Cocoa
import Combine

/// Main cursor engine — coordinates overlay, tracking, and animations.
@MainActor
final class CursorEngine: ObservableObject {

    // MARK: - Published state
    @Published var isEnabled: Bool = false {
        didSet { isEnabled ? start() : stop() }
    }
    @Published var currentTheme: CursorTheme?
    @Published var cursorScale: Double = 1.0
    @Published var trailEnabled: Bool = false

    // MARK: - Components
    private var overlay: CursorOverlay?
    private let tracker = CursorTracker()
    private let animation = CursorAnimation()
    private let stateDetector = CursorStateDetector()

    // MARK: - State
    private var loadedImages: [String: NSImage] = [:]
    private var loadedAnimations: [String: [CursorAnimation.Frame]] = [:]
    private var currentRole: CursorRole = .defaultCursor
    private var hasCustomCursorImage: Bool = false
    private var cursorReinforceTimer: Timer?

    // MARK: - Paths
    private let appSupportURL: URL
    private let defaultThemeDir: URL

    static let shared = CursorEngine()

    private init() {
        let fm = FileManager.default
        appSupportURL = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("CursorVibe")
        defaultThemeDir = appSupportURL.appendingPathComponent("Cursors/default")
        try? fm.createDirectory(at: defaultThemeDir, withIntermediateDirectories: true)
        setupBindings()
        ensureDefaultCursorsExist()
    }

    // MARK: - Setup

    private func setupBindings() {
        tracker.onMove = { [weak self] point in
            self?.overlay?.updatePosition(point)
        }
        tracker.onStateChange = { [weak self] state in
            self?.handleCursorStateChange(state)
        }
        tracker.onMouseDown = { [weak self] _ in
            self?.handleClick()
        }
    }

    private func ensureDefaultCursorsExist() {
        let testFile = defaultThemeDir.appendingPathComponent("\(CursorRole.defaultCursor.rawValue).png")
        if !FileManager.default.fileExists(atPath: testFile.path) {
            CursorRenderer.generateSystemCursorSet(in: defaultThemeDir)
            let manifest = CursorTheme.defaultTheme
            if let data = try? JSONEncoder().encode(manifest) {
                try? data.write(to: defaultThemeDir.appendingPathComponent("manifest.json"))
            }
        }
    }

    // MARK: - Start/Stop

    private func start() {
        loadImagesForCurrentTheme()
        guard hasCustomCursorImage else {
            print("[CursorEngine] No cursor images loaded")
            return
        }

        overlay = CursorOverlay()
        overlay?.showOverlay()
        tracker.start()
        applyCurrentCursor()

        // Periodically reinforce the invisible cursor (some apps reset it)
        cursorReinforceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tracker.reinforceInvisibleCursor()
            }
        }

        // Accessibility-based state detection
        stateDetector.startDetection(interval: 0.15) { [weak self] role in
            guard let self = self else { return }
            if role != self.currentRole {
                self.currentRole = role
                self.applyCurrentCursor()
            }
        }
    }

    private func stop() {
        cursorReinforceTimer?.invalidate()
        cursorReinforceTimer = nil
        stateDetector.stopDetection()
        tracker.stop()
        overlay?.hideOverlay()
        overlay = nil
        animation.stop()
        currentRole = .defaultCursor
    }

    // MARK: - Theme management

    func loadTheme(from directory: URL) {
        let manifestURL = directory.appendingPathComponent("manifest.json")
        guard let data = try? Data(contentsOf: manifestURL) else { return }
        let decoder = JSONDecoder()
        guard let theme = try? decoder.decode(CursorTheme.self, from: data) else { return }
        currentTheme = theme
        loadImages(from: directory, theme: theme)
        if isEnabled { stop(); start() }
    }

    func applyTheme(_ theme: CursorTheme) {
        currentTheme = theme
        loadImagesForCurrentTheme()
        if isEnabled { stop(); start() }
    }

    func loadImagesForCurrentTheme() {
        guard let theme = currentTheme else {
            loadImages(from: defaultThemeDir, theme: .defaultTheme)
            currentTheme = .defaultTheme
            return
        }
        let packDir: URL
        if theme.isBuiltIn {
            packDir = defaultThemeDir
        } else {
            packDir = appSupportURL.appendingPathComponent("Packs").appendingPathComponent(theme.id)
        }
        loadImages(from: packDir, theme: theme)
    }

    private func loadImages(from directory: URL, theme: CursorTheme) {
        loadedImages.removeAll()
        loadedAnimations.removeAll()
        for cursor in theme.cursors {
            let imageURL = directory.appendingPathComponent(cursor.imageFile)
            if let image = NSImage(contentsOf: imageURL) {
                loadedImages[cursor.id] = scaledImage(image, scale: cursor.scale)
            }
            if let animFile = cursor.animatedFile, cursor.fps > 0 {
                let animURL = directory.appendingPathComponent(animFile)
                let anim = CursorAnimation()
                anim.loadFromAnimatedImages(at: animURL) { _ in }
                if !anim.frames.isEmpty {
                    loadedAnimations[cursor.id] = anim.frames
                }
            }
        }
        hasCustomCursorImage = !loadedImages.isEmpty
    }

    // MARK: - Apply cursor

    private func applyCurrentCursor() {
        let roleKey = currentRole.rawValue
        let hotspot = hotspotForCurrentCursor()

        if let frames = loadedAnimations[roleKey], !frames.isEmpty {
            animation.loadFromImages(frames.map(\.image), frameDuration: frames[0].duration) { [weak self] image in
                self?.overlay?.setCursorImage(image, hotspot: hotspot)
            }
            animation.play()
            return
        }

        animation.stop()
        let image = loadedImages[roleKey] ?? loadedImages[CursorRole.defaultCursor.rawValue]
        overlay?.setCursorImage(image, hotspot: hotspot)
    }

    private func hotspotForCurrentCursor() -> NSPoint {
        guard let theme = currentTheme else { return NSPoint(x: 4, y: 4) }
        let roleKey = currentRole.rawValue
        if let def = theme.cursors.first(where: { $0.id == roleKey }) {
            let imgSize = loadedImages[roleKey]?.size ?? NSSize(width: 32, height: 32)
            // Hotspot is from top-left, but we pass it as-is to overlay which handles the conversion
            return NSPoint(x: def.hotspot.x * imgSize.width, y: def.hotspot.y * imgSize.height)
        }
        return NSPoint(x: 4, y: 4)
    }

    // MARK: - State handling

    private func handleCursorStateChange(_ state: CursorTracker.CursorState) {
        let newRole: CursorRole = switch state {
        case .normal:    .defaultCursor
        case .pointing:  .pointer
        case .text:      .text
        case .dragging:  .drag
        case .resize:    .resizeNS
        case .copy:      .copy
        case .forbidden: .notAllowed
        case .wait:      .wait
        }
        guard newRole != currentRole else { return }
        currentRole = newRole
        applyCurrentCursor()
    }

    private func handleClick() {}

    // MARK: - Helpers

    private func scaledImage(_ image: NSImage, scale: Double) -> NSImage {
        guard scale != 1.0 else { return image }
        let w = image.size.width * CGFloat(scale)
        let h = image.size.height * CGFloat(scale)
        let scaled = NSImage(size: NSSize(width: w, height: h))
        scaled.lockFocus()
        image.draw(in: NSRect(x: 0, y: 0, width: w, height: h), from: .zero, operation: .sourceOver, fraction: 1.0)
        scaled.unlockFocus()
        return scaled
    }
}
