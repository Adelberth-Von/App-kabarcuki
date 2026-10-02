// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "KabarCore", platforms: [.iOS(.v16), .macOS(.v13)], products: [.library(name: "KabarCore", targets: ["KabarCore"])], targets: [.target(name: "KabarCore"), .testTarget(name: "KabarCoreTests", dependencies: ["KabarCore"])])
