import Foundation

public struct CocoaPodsDependencies: Equatable {

    public enum Pod: Equatable, Codable {
        case remote(name: String, source: PodSource)
    }

    public enum PodSource: Codable, Equatable {
        case tag(String)
        case branch(String)
        case revision(String)
    }

    public let pods: [Pod]

    // The base settings to be used for targets generated from SwiftPackageManager
    public let baseSettings: Settings

    /// The custom `Settings` to be applied to SPM targets
    public let targetSettings: [String: SettingsDictionary]

    public init(
        pods: [Pod],
        baseSettings: Settings,
        targetSettings: [String: SettingsDictionary]
    ) {
        self.pods = pods
        self.baseSettings = baseSettings
        self.targetSettings = targetSettings
    }
}
