// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CursorVibe",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "CursorVibe", targets: ["CursorVibe"]),
    ],
    dependencies: [
        // RevenueCat for subscriptions (add later)
        // .package(url: "https://github.com/RevenueCat/purchases-ios.git", from: "5.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "CursorVibe",
            dependencies: [],
            path: "CursorVibe",
            exclude: ["Resources"],
        ),
    ]
)
