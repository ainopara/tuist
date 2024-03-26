import Foundation
import ProjectDescription
import TSCBasic
import TuistCore
import TuistGraph
import TuistSupport

extension TuistGraph.CocoaPodsDependencies {
    /// Creates `TuistGraph.CocoaPodsDependencies` instance from `ProjectDescription.CocoaPodsDependencies`
    /// instance.
    static func from(
        manifest: ProjectDescription.CocoapodDependencies,
        generatorPaths: GeneratorPaths
    ) throws -> Self {
        let baseSettings = try TuistGraph.Settings.from(manifest: manifest.baseSettings, generatorPaths: generatorPaths)
        let targetSettings = manifest.targetSettings.mapValues { TuistGraph.SettingsDictionary.from(manifest: $0) }

        return .init(
            pods: try manifest.pods.map { manifest in
                return try CocoaPodsDependencies.Pod.from(manifest: manifest)
            },
            baseSettings: baseSettings,
            targetSettings: targetSettings
        )
    }
}

extension TuistGraph.CocoaPodsDependencies.Pod {
    static func from(manifest: ProjectDescription.Pod) throws -> Self {
        switch manifest {
        case .remote(let name, let source):
            return .remote(name: name, source: try CocoaPodsDependencies.PodSource.from(manifest: source))
        }
    }
}

extension TuistGraph.CocoaPodsDependencies.PodSource {
    static func from(manifest: ProjectDescription.PodSource) throws -> Self {
        switch manifest {
        case .tag(let tag):
            return .tag(tag)
        case .branch(let branch):
            return .branch(branch)
        case .revision(let revision):
            return .revision(revision)
        }
    }
}
