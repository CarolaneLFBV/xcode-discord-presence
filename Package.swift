// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "XcodePresence",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "XcodePresence", targets: ["XcodePresence"])],
    targets: [
        .target(name: "PresenceCore"),
        .executableTarget(name: "XcodePresence", dependencies: ["PresenceCore"]),
        .testTarget(name: "PresenceCoreTests", dependencies: ["PresenceCore"]),
        .testTarget(name: "XcodePresenceTests", dependencies: ["XcodePresence"]),
    ]
)
