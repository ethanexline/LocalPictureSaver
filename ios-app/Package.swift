// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LocalPictureSaverApp",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .executable(name: "LocalPictureSaverApp", targets: ["LocalPictureSaverApp"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "LocalPictureSaverApp",
            dependencies: [],
            path: "Sources"
        )
    ]
)
