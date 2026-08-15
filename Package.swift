// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WinnerPicker",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "WinnerPicker"
        )
    ]
)
