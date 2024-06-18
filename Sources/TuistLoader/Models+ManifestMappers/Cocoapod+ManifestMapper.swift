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
            sources: manifest.sources.map { manifest in CocoaPodsDependencies.PodSpecSource.from(manifest: manifest) },
            pods: try manifest.pods.map { manifest in
                return try CocoaPodsDependencies.Pod.from(manifest: manifest)
            },
            baseSettings: baseSettings,
            targetSettings: targetSettings
        )
    }
}

extension TuistGraph.CocoaPodsDependencies.PodSpecSource {
    static func from(manifest: ProjectDescription.PodSpecSource) -> Self {
        return .init(name: manifest.name, url: manifest.url, isCDN: manifest.isCDN)
    }
}

extension TuistGraph.CocoaPodsDependencies.Pod {
    static func from(manifest: ProjectDescription.Pod) throws -> Self {
        switch manifest {
        case .remote(let name, let source, let subspecs, let generateModularHeaders):
            return .remote(
                name: name,
                source: try CocoaPodsDependencies.PodSource.from(manifest: source),
                subspecs: subspecs,
                generateModularHeaders: generateModularHeaders
            )
        }
    }
}

extension TuistGraph.CocoaPodsDependencies.PodSource {
    static func from(manifest: ProjectDescription.PodSource) throws -> Self {
        switch manifest {
        case .version(let version):
            return .version(version)
        case .podspec(let path):
            return .podspec(path: path)
        }
    }
}
