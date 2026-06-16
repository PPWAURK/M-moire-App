// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Meimoire",
    defaultLocalization: "fr",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Meimoire", targets: ["Meimoire"]),
        .library(name: "MeimoireCore", targets: ["MeimoireCore"])
    ],
    targets: [
        .target(
            name: "MeimoireCore",
            linkerSettings: [
                .linkedFramework("Security"),
                .linkedFramework("LocalAuthentication")
            ]
        ),
        .executableTarget(
            name: "Meimoire",
            dependencies: ["MeimoireCore"]
        ),
        .testTarget(
            name: "MeimoireTests",
            dependencies: ["MeimoireCore"]
        )
    ]
)
