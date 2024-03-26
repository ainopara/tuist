import Foundation

public struct Dependencies: Equatable {
    public let carthage: CarthageDependencies?
    public let swiftPackageManager: SwiftPackageManagerDependencies?
    public let cocoaPods: CocoaPodsDependencies?
    public let platforms: Set<PackagePlatform>

    public init(
        carthage: CarthageDependencies?,
        swiftPackageManager: SwiftPackageManagerDependencies?,
        cocoaPods: CocoaPodsDependencies? = nil,
        platforms: Set<PackagePlatform>
    ) {
        self.carthage = carthage
        self.swiftPackageManager = swiftPackageManager
        self.cocoaPods = cocoaPods
        self.platforms = platforms
    }
}
