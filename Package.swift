// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TokamakPathIssue",
    platforms: [.macOS(.v12), .iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "TokamakPathIssue",
            targets: ["TokamakPathIssue"]),
        .executable(
            name: "TokamakPathIssueApp",
            targets: ["TokamakPathIssueApp"]),
    ],
    dependencies: [
      .package(url: "https://github.com/TokamakUI/Tokamak.git", branch: "main"),
      .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", from: "0.15.0")
    ],
    targets: [
        .target(
            name: "TokamakPathIssue",
            dependencies: [
              .product(name: "TokamakShim", package: "Tokamak"),
              .product(name: "JavaScriptKit", package: "JavaScriptKit"),
              .product(name: "JavaScriptEventLoop", package: "JavaScriptKit"),
            ]),
      
        .executableTarget(
          name: "TokamakPathIssueApp",
          dependencies: ["TokamakPathIssue",
                         .product(name: "TokamakShim", package: "Tokamak"),
                         .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                         .product(name: "JavaScriptEventLoop", package: "JavaScriptKit")
          ],
          linkerSettings: [
              .unsafeFlags(
                ["-Xlinker", "--stack-first", "-Xlinker", "-z", "-Xlinker", "stack-size=32777216"],
                .when(platforms: [.wasi])
              ),
          ]
        )
    ]
)
