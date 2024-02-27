import Foundation

public struct CocoaPodDependencies: Equatable {

    // The base settings to be used for targets generated from SwiftPackageManager
    public let baseSettings: Settings

    /// The custom `Settings` to be applied to SPM targets
    public let targetSettings: [String: SettingsDictionary]

    public init(
        baseSettings: Settings,
        targetSettings: [String: SettingsDictionary]
    ) {
        self.baseSettings = baseSettings
        self.targetSettings = targetSettings
    }
}
