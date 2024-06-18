import Foundation

public struct CocoaPodsDependencies: Equatable {

    public struct PodSpecSource: Codable, Equatable {
        public let name: String
        public let url: String
        public let isCDN: Bool

        public init(name: String, url: String, isCDN: Bool) {
            self.name = name
            self.url = url
            self.isCDN = isCDN
        }
    }

    public enum Pod: Equatable, Codable {
        case remote(
            name: String,
            source: PodSource,
            subspecs: [String]?,
            generateModularHeaders: Bool
        )
    }

    public enum PodSource: Codable, Equatable {
        case version(String)
        case podspec(path: String)
    }

    public let sources: [PodSpecSource]

    public let pods: [Pod]

    // The base settings to be used for targets generated from SwiftPackageManager
    public let baseSettings: Settings

    /// The custom `Settings` to be applied to SPM targets
    public let targetSettings: [String: SettingsDictionary]

    public init(
        sources: [PodSpecSource],
        pods: [Pod],
        baseSettings: Settings,
        targetSettings: [String: SettingsDictionary]
    ) {
        self.sources = sources
        self.pods = pods
        self.baseSettings = baseSettings
        self.targetSettings = targetSettings
    }
}
