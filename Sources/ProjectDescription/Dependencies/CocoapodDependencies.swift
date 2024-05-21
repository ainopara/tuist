import Foundation

public struct CocoapodDependencies: Codable, Equatable {

    public let sources: [PodSpecSource]

    public let pods: [Pod]

    // The base settings to be used for targets generated from SwiftPackageManager
    public let baseSettings: Settings

    // Additional settings to be added to targets generated from SwiftPackageManager.
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
