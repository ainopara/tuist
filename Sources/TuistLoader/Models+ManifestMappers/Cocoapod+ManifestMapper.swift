import Foundation
import ProjectDescription
import TSCBasic
import TuistCore
import TuistGraph
import TuistSupport

extension TuistGraph.CocoaPodDependencies {
    /// Creates `TuistGraph.CocoaPodDependencies` instance from `ProjectDescription.CocoaPodDependencies`
    /// instance.
    static func from(
        manifest: ProjectDescription.CocoapodDependencies,
        generatorPaths: GeneratorPaths
    ) throws -> Self {
        let baseSettings = try TuistGraph.Settings.from(manifest: manifest.baseSettings, generatorPaths: generatorPaths)
        let targetSettings = manifest.targetSettings.mapValues { TuistGraph.SettingsDictionary.from(manifest: $0) }

        return .init(
            baseSettings: baseSettings,
            targetSettings: targetSettings
        )
    }
}
