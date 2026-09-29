import Cocoa

/// Handles frame-based cursor animations from sprite sheets, GIFs, and APNGs.
final class CursorAnimation {

    struct Frame {
        let image: NSImage
        let duration: TimeInterval  // seconds
    }

    struct SpriteSheet {
        let image: NSImage
        let frameWidth: CGFloat
        let frameHeight: CGFloat
        let columns: Int
        let rows: Int
        let frameCount: Int
        let frameDuration: TimeInterval
    }

    private(set) var frames: [Frame] = []
    private(set) var isPlaying = false
    private var currentFrameIndex = 0
    private var animationTimer: Timer?
    private var onAnimationUpdate: ((NSImage) -> Void)?

    // MARK: - Load from sprite sheet

    func loadFromSpriteSheet(_ sheet: SpriteSheet, onUpdate: @escaping (NSImage) -> Void) {
        onAnimationUpdate = onUpdate
        frames = extractFrames(from: sheet)
    }

    func loadFromImages(_ images: [NSImage], frameDuration: TimeInterval, onUpdate: @escaping (NSImage) -> Void) {
        onAnimationUpdate = onUpdate
        frames = images.map { Frame(image: $0, duration: frameDuration) }
    }

    func loadFromGIF(data: Data, onUpdate: @escaping (NSImage) -> Void) {
        onAnimationUpdate = onUpdate
        frames = decodeGIF(data: data)
    }

    func loadFromAnimatedImages(at url: URL, onUpdate: @escaping (NSImage) -> Void) {
        onAnimationUpdate = onUpdate
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "gif":
            if let data = try? Data(contentsOf: url) {
                frames = decodeGIF(data: data)
            }
        case "apng", "png":
            frames = decodeAPNG(at: url)
        default:
            // Try as static image sequence directory
            frames = loadSequenceFromDirectory(url)
        }
    }

    // MARK: - Playback control

    func play() {
        guard !frames.isEmpty, !isPlaying else { return }
        isPlaying = true
        currentFrameIndex = 0
        scheduleNextFrame()
    }

    func stop() {
        isPlaying = false
        animationTimer?.invalidate()
        animationTimer = nil
    }

    func reset() {
        stop()
        currentFrameIndex = 0
        if let first = frames.first {
            onAnimationUpdate?(first.image)
        }
    }

    // MARK: - Sprite sheet extraction

    private func extractFrames(from sheet: SpriteSheet) -> [Frame] {
        var result: [Frame] = []
        let cols = sheet.columns
        let rows = sheet.rows
        let totalFrames = min(sheet.frameCount, cols * rows)

        for i in 0..<totalFrames {
            let col = i % cols
            let row = i / cols
            let rect = NSRect(
                x: CGFloat(col) * sheet.frameWidth,
                y: CGFloat(row) * sheet.frameHeight,
                width: sheet.frameWidth,
                height: sheet.frameHeight
            )

            if let cgImage = sheet.image.cgImage(forProposedRect: nil, context: nil, hints: nil),
               let cropped = cgImage.cropping(to: rect) {
                let frameImage = NSImage(cgImage: cropped, size: NSSize(width: sheet.frameWidth, height: sheet.frameHeight))
                result.append(Frame(image: frameImage, duration: sheet.frameDuration))
            }
        }
        return result
    }

    // MARK: - GIF decoding

    private func decodeGIF(data: Data) -> [Frame] {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return [] }
        let count = CGImageSourceGetCount(source)
        var result: [Frame] = []

        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }

            var duration: TimeInterval = 0.1
            if let props = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
               let gifDict = props[kCGImagePropertyGIFDictionary as String] as? [String: Any],
               let delay = gifDict[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double {
                duration = max(delay, 0.02)  // minimum 20ms
            }

            let size = NSSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
            let image = NSImage(cgImage: cgImage, size: size)
            result.append(Frame(image: image, duration: duration))
        }
        return result
    }

    // MARK: - APNG decoding

    private func decodeAPNG(at url: URL) -> [Frame] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        // APNG is technically PNG with animation chunks
        // Use CGImageSource which handles APNG on macOS 14+
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return [] }
        let count = CGImageSourceGetCount(source)
        guard count > 1 else { return [] }  // Not animated

        var result: [Frame] = []
        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            var duration: TimeInterval = 0.1
            if let props = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any] {
                // Try APNG dictionary first, fall back to GIF dictionary
                if let apngDict = props["{APNG}"] as? [String: Any],
                   let delay = apngDict["UnclampedDelayTime"] as? Double {
                    duration = max(delay, 0.02)
                } else if let gifDict = props[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                          let delay = gifDict[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double {
                    duration = max(delay, 0.02)
                }
            }
            let size = NSSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
            let image = NSImage(cgImage: cgImage, size: size)
            result.append(Frame(image: image, duration: duration))
        }
        return result
    }

    // MARK: - Image sequence directory

    private func loadSequenceFromDirectory(_ url: URL) -> [Frame] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        let imageFiles = files
            .filter { ["png", "gif", "tiff", "jpg"].contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        return imageFiles.compactMap { fileURL -> Frame? in
            guard let image = NSImage(contentsOf: fileURL) else { return nil }
            return Frame(image: image, duration: 1.0 / 24.0)
        }
    }

    // MARK: - Timer

    private func scheduleNextFrame() {
        guard isPlaying, !frames.isEmpty else { return }
        let frame = frames[currentFrameIndex]
        onAnimationUpdate?(frame.image)

        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: frame.duration, repeats: false) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            self.currentFrameIndex = (self.currentFrameIndex + 1) % self.frames.count
            self.scheduleNextFrame()
        }
    }
}
