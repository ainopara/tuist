import Foundation

public struct CocoaPodsDependencies: Equatable {

    public enum Pod: Equatable, Codable {
        case remote(
            name: String,
            source: PodSource,
            subspecs: [String]?,
            generateModularHeaders: Bool,
            configurations: [String]?
        )
    }

    public enum PodSource: Codable, Equatable {
        case version(String)
        case podspec(path: String)
        case gitWithTag(source: String, tag: String)
        case gitWithCommit(source: String, commit: String)
        case gitWithBranch(source: String, branch: String)
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
