import Foundation

public struct Dependencies: Equatable {
    public let carthage: CarthageDependencies?
    public let swiftPackageManager: SwiftPackageManagerDependencies?
    public let cocoapod: CocoaPodDependencies?
    public let platforms: Set<PackagePlatform>

    public init(
        carthage: CarthageDependencies?,
        swiftPackageManager: SwiftPackageManagerDependencies?,
        cocoapod: CocoaPodDependencies?,
        platforms: Set<PackagePlatform>
    ) {
        self.carthage = carthage
        self.swiftPackageManager = swiftPackageManager
        self.cocoapod = cocoapod
        self.platforms = platforms
    }
}
