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
        case .remote(let name, let source, let subspecs, let generateModularHeaders, let configurations):
            return .remote(
                name: name,
                source: try CocoaPodsDependencies.PodSource.from(manifest: source),
                subspecs: subspecs,
                generateModularHeaders: generateModularHeaders,
                configurations: configurations
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
        case .gitWithTag(let source, let tag):
            return .gitWithTag(source: source, tag: tag)
        case .gitWithCommit(let source, let commit):
            return .gitWithCommit(source: source, commit: commit)
        case .gitWithBranch(let source, let branch):
            return .gitWithBranch(source: source, branch: branch)
        }
    }
}
