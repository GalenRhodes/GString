// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

//@f:0
let package = Package(
    name: "GString",
    platforms: [ .macOS(.v11), .tvOS(.v14), .iOS(.v14), .watchOS(.v7) ],
    products: [ .library(name: "GString", targets: [ "GString" ]), ],
    dependencies: [],
    targets: [
        .target(name: "GString", dependencies: [], exclude: []),
        .testTarget(name: "GStringTests", dependencies: [ "GString" ], exclude: []),
    ])
//@f:1
