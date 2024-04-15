import ProjectDescription
import TSCBasic
import TSCUtility
import TuistCore
import TuistGraph
import TuistSupport
import Foundation
import TuistLoader

public protocol CocoaPodsInteracting {
    /// Installs `Cocoapod` dependencies.
    /// - Parameters:
    ///   - dependenciesDirectory: The path to the directory that contains the `Tuist/Dependencies/` directory.
    ///   - dependencies: List of dependencies to install using `CocoaPods`.
    ///   - platforms: Set of supported platforms.
    ///   - shouldUpdate: Indicates whether dependencies should be updated or fetched based on the lockfile.
    func install(
        dependenciesDirectory: AbsolutePath,
        dependencies: TuistGraph.CocoaPodsDependencies,
        platforms: Set<TuistGraph.PackagePlatform>,
        shouldUpdate: Bool
    ) throws -> TuistCore.DependenciesGraph

    /// Removes all cached `Cocoapod` dependencies.
    /// - Parameter dependenciesDirectory: The path to the directory that contains the `Tuist/Dependencies/` directory.
    func clean(dependenciesDirectory: AbsolutePath) throws
}

// MARK: - CocoaPods Interactor

public final class CocoaPodsInteractor: CocoaPodsInteracting {
    private let fileHandler: FileHandling
    private let cocoaPodsController: CocoaPodsControlling

    public init(
        fileHandler: FileHandling = FileHandler.shared,
        cocoaPodsController: CocoaPodsControlling = CocoaPodsController.shared
    ) {
        self.fileHandler = fileHandler
        self.cocoaPodsController = cocoaPodsController
    }

    public func install(
        dependenciesDirectory: AbsolutePath,
        dependencies: TuistGraph.CocoaPodsDependencies,
        platforms: Set<TuistGraph.PackagePlatform>,
        shouldUpdate: Bool
    ) throws -> TuistCore.DependenciesGraph {
        logger.info("Installing CocoaPods dependencies.", metadata: .subsection)

        let pathsProvider = CocoaPodsPathsProvider(dependenciesDirectory: dependenciesDirectory)

        let savedCWD = localFileSystem.currentWorkingDirectory
        try localFileSystem.changeCurrentWorkingDirectory(to: pathsProvider.destinationCocoaPodsDirectory)
        
        defer {
            if let savedCWD = savedCWD {
                try! localFileSystem.changeCurrentWorkingDirectory(to: savedCWD)
            }
        }

        try generateProjectSwiftFile(pathsProvider: pathsProvider)
        try generatePodfile(pathsProvider: pathsProvider, dependencies: dependencies, platforms: platforms)
        try loadDependencies(pathsProvider: pathsProvider, dependencies: dependencies)

        if shouldUpdate {
            try cocoaPodsController.update(at: pathsProvider.destinationCocoaPodsDirectory, printOutput: true)
        } else {
            try cocoaPodsController.install(at: pathsProvider.destinationCocoaPodsDirectory, printOutput: true)
        }

        try saveDependencies(pathsProvider: pathsProvider)

        // Generate graph
        let specs = try readSpecs(pathsProvider: pathsProvider)

        var externalProjects: [Path: ProjectDescription.Project] = [:]
        var externalDependencies: [String: [ProjectDescription.TargetDependency]] = [:]

        var descriptionBaseSettings: ProjectDescription.SettingsDictionary = convert(dependencies.baseSettings.base)

        descriptionBaseSettings = descriptionBaseSettings
            .applying(operation: .add(policy: .merge, settings: [
                "GCC_PREPROCESSOR_DEFINITIONS": ["$(inherited)", "COCOAPODS=1"],
                "OTHER_SWIFT_FLAGS": ["$(inherited)", "-D", "COCOAPODS"]
            ]))
            .applying(operation: .add(policy: .replace, settings: [
                "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER": "NO",
                "PODS_BUILD_DIR": "${BUILD_DIR}",
                "PODS_CONFIGURATION_BUILD_DIR": "${PODS_BUILD_DIR}/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)",
                "PODS_ROOT": "${SRCROOT}/.."
            ]))

        var descriptionConfigurations: [ProjectDescription.Configuration] = []
        
        for (key, value) in dependencies.baseSettings.configurations {
            switch key.variant {
            case .debug:
                descriptionConfigurations.append(ProjectDescription.Configuration.debug(
                    name: ConfigurationName(stringLiteral: key.name),
                    settings: {
                        if let value {
                            return convert(value.settings)
                        } else {
                            return [:]
                        }
                    }()
                ))
            case .release:
               descriptionConfigurations.append(ProjectDescription.Configuration.release(
                   name: ConfigurationName(stringLiteral: key.name),
                   settings: {
                       if let value {
                           return convert(value.settings)
                       } else {
                           return [:]
                       }
                   }()
               ))
            }
        }

        var subspecDictionarry: [String: [String]] = [:]
        for case .remote(let name, _, let subpsecs) in dependencies.pods {
            subspecDictionarry[name] = subpsecs
        }

        for spec in specs {
            let resolvedSpec = spec.resolvePodspec(selectedSubspecs: subspecDictionarry[spec.name])
            let (specProject, specDependencies) = generateProjectDescription(
                for: resolvedSpec,
                descriptionBaseSettings: descriptionBaseSettings,
                descriptionConfigurations: descriptionConfigurations,
                targetSettings: dependencies.targetSettings,
                podsDirectoryPath: pathsProvider.destinationPodsDirectory
            )
            externalProjects.merge(specProject, uniquingKeysWith: { $1 })
            externalDependencies.merge(specDependencies, uniquingKeysWith: { $1 })
        }
        return .init(externalDependencies: externalDependencies, externalProjects: externalProjects)
    }

    public func clean(dependenciesDirectory: AbsolutePath) throws {

    }

    func convert(_ settingsDictionary: TuistGraph.SettingsDictionary) -> ProjectDescription.SettingsDictionary {
        settingsDictionary.mapValues {
            switch $0 {
            case .array(let array): return .array(array)
            case .string(let string): return .string(string)
            }
        }
    }

    func generateProjectDescription(
        for spec: Podspec,
        descriptionBaseSettings: ProjectDescription.SettingsDictionary,
        descriptionConfigurations: [ProjectDescription.Configuration],
        targetSettings: [String: TuistGraph.SettingsDictionary],
        podsDirectoryPath: AbsolutePath
    ) -> ([Path: ProjectDescription.Project], [String: [ProjectDescription.TargetDependency]]) {

        var externalProjects: [Path: ProjectDescription.Project] = [:]
        var externalDependencies: [String: [ProjectDescription.TargetDependency]] = [:]

        if spec.isWrapperPod {
            var result = [ProjectDescription.TargetDependency]()
            result += spec.expandVendoredFramework(podsPath: podsDirectoryPath)
            result += (spec.libraries ?? []) .map {
                .sdk(name: $0, type: .library, status: .required, condition: nil)
            }

            result += (spec.frameworks ?? []).map {
                .sdk(name: $0, type: .framework, status: .required, condition: nil)
            }

            result += (spec.weakFrameworks ?? []).map {
                .sdk(name: $0, type: .framework, status: .optional, condition: nil)
            }
            externalDependencies[spec.name] = result
        } else {
            let manifestPath = Path(podsDirectoryPath.appending(component: spec.name).pathString)

            var specSpecificConfigurations = descriptionConfigurations
            for (index, configuration) in specSpecificConfigurations.enumerated() {

                if let settings = targetSettings[spec.name] {
                    let convertedSettings = convert(settings)
                    for (key, value) in convertedSettings {
                        specSpecificConfigurations[index].settings[key] = value
                    }
                }

                if let moduleName = spec.moduleName {
                    specSpecificConfigurations[index].settings["PRODUCT_MODULE_NAME"] = .string(moduleName)
                }

                if let moduleMap = spec.moduleMap {
                    specSpecificConfigurations[index].settings["MODULEMAP_FILE"] = .string(moduleMap)
                } else {
                    let generatedModuleMapPath = try! AbsolutePath(
                        podsDirectoryPath,
                        RelativePath(validating: "Target Support Files/\(spec.name)/\(spec.name).modulemap")
                    )
                    if localFileSystem.exists(generatedModuleMapPath) {
                        specSpecificConfigurations[index].settings["MODULEMAP_FILE"] = .string("../Target Support Files/\(spec.name)/\(spec.name).modulemap")
                    }
                }

                if ["YTKRouterManager", "VGOWeb", "VGOFoundation", "VGOUIKit", "YTKCoreText", "ProtocolBuffers"].contains(spec.name) {
                    specSpecificConfigurations[index].settings["GCC_PREFIX_HEADER"] = .string("../Target Support Files/\(spec.name)/\(spec.name)-prefix.pch")
                }

                specSpecificConfigurations[index].settings["PODS_TARGET_SRCROOT"] = .string("${PODS_ROOT}/\(spec.name)")

                if let podTargetXcconfig = spec.podTargetXcconfig {
                    for (key, value) in podTargetXcconfig {
                        specSpecificConfigurations[index].settings = specSpecificConfigurations[index].settings
                            .applying(operation: .add(policy: .merge, settings: [key: .array(value.wrappedValue ?? [])]))
                    }
                }
            }

            func resolveGlobs(manifestPath: Path, globs: [String]) -> [String] {
                let generatorPaths = try! GeneratorPaths(manifestDirectory: AbsolutePath(validating: manifestPath.pathString))
                let sources = try! globs
                    .map { try generatorPaths.resolve(path: Path($0)) }
                    .compactMap { Array(Glob(pattern: $0.pathString)) }
                    .reduce(Set<String>()) { partialResult, next in return partialResult.union(next) }
                return Array(sources)
            }

            let sourceGlobs: [String] = (spec.sourceFiles ?? []).flatMap { cocoaPodsGlob in
                Podspec.convertToGlob(from: cocoaPodsGlob)
            }
            let sources = resolveGlobs(manifestPath: manifestPath, globs: sourceGlobs)
            var sharedCompilerFlags = spec.compilerFlags ?? []
            var customCompilerFlagsDictionary: [String: [String]] = [:]

            func filterSources(_ sources: [String], hasExtensionIn extensions: [String]) -> [String] {
                sources
                    .filter { path in
                        let ext = (path as NSString).pathExtension
                        guard !ext.isEmpty else { return false }
                        return extensions
                            .contains(where: { $0.caseInsensitiveCompare(ext) == .orderedSame })
                    }
            }

            func isSource(_ source: String, hasExtensionIn extensions: [String]) -> Bool {
                let ext = (source as NSString).pathExtension
                guard !ext.isEmpty else { return false }
                return extensions.contains(where: { $0.caseInsensitiveCompare(ext) == .orderedSame })
            }

            func compilerFlags(for filePath: String) -> [String] {
                if isSource(filePath, hasExtensionIn: ["s"]) { return [] }
                return sharedCompilerFlags + (customCompilerFlagsDictionary[filePath] ?? [])
            }

            let validSources = filterSources(sources, hasExtensionIn: Target.validSourceExtensions)

            switch spec.requiresArc {
            case .bool(let boolValue):
                if boolValue == false {
                    sharedCompilerFlags.append("-fno-objc-arc")
                }
            case .array(let globs):
                let sourcesWhoRequireArc = resolveGlobs(manifestPath: manifestPath, globs: globs)
                let sourcesWhoDoNotRequireArc = Set(validSources).subtracting(sourcesWhoRequireArc)
                for source in sourcesWhoDoNotRequireArc {
                    customCompilerFlagsDictionary[source, default: []] += ["-fno-objc-arc"]
                }
            case .none:
                break
            }

            let privateHeaderGlobs: [String] = spec.privateHeaderFiles ?? []

            let publicHeaderGlobs: [String] = {
                var result: [String] = []
                if let headerFiles = spec.publicHeaderFiles {
                    result += headerFiles.flatMap { headerFile in Podspec.convertToGlob(from: headerFile) }
                } else {
                    result += sourceGlobs
                }
                if let headerDir = spec.headerDir {
                    result += Podspec.convertToGlob(from: headerDir)
                }
                result += ["../Target Support Files/\(spec.name)/\(spec.name)-umbrella.h"]
                return result
            }()

            let depenencies: [ProjectDescription.TargetDependency] = {
                var result: [ProjectDescription.TargetDependency] = []

                result += spec.expandVendoredFramework(podsPath: podsDirectoryPath)

                result += (spec.libraries ?? []).map {
                    .sdk(name: $0, type: .library, status: .required, condition: nil)
                }

                result += (spec.frameworks ?? []).map {
                    .sdk(name: $0, type: .framework, status: .required, condition: nil)
                }

                result += (spec.weakFrameworks ?? []).map {
                    .sdk(name: $0, type: .framework, status: .optional, condition: nil)
                }

                result += (spec.dependencies ?? [:]).keys.map { dependencyName in
                    if dependencyName.contains("/") {
                        // Convert subspec dependencies like "GTM/zlib" to "GTM"
                        return .external(name: String(dependencyName.split(separator: "/").first!))
                    } else {
                        return .external(name: dependencyName)
                    }
                }

                return result
            }()

            externalProjects[manifestPath] = ProjectDescription.Project(
                name: spec.name,
                settings: .settings(base: descriptionBaseSettings, configurations: specSpecificConfigurations),
                targets: [
                    Target(
                        name: spec.name,
                        destinations: .iOS,
                        product: .staticFramework,
                        productName: spec.moduleName,
                        bundleId: "org.cocoapods.\(spec.name)".replacingOccurrences(of: "_", with: "-"),
                        deploymentTargets: .iOS("12.0"),
                        infoPlist: .default,
                        sources: {
                            if !validSources.isEmpty {
                                return ProjectDescription.SourceFilesList(
                                    globs: validSources.map {
                                        ProjectDescription.SourceFileGlob.file(
                                            Path($0),
                                            compilerFlags: compilerFlags(for: $0).joined(separator: " ")
                                        )
                                    }
                                )
                            } else {
                                return nil
                            }
                        }(),
                        headers: {
                            return ProjectDescription.Headers.headers(
                                public: FileList.list(
                                    publicHeaderGlobs.map { (glob: String) -> FileListGlob in
                                        ProjectDescription.FileListGlob.glob(
                                            Path(glob),
                                            excluding: privateHeaderGlobs.map { Path($0) }
                                        )
                                    }
                                ),
                                private: FileList.list(
                                    privateHeaderGlobs.map { (glob: String) -> FileListGlob in
                                        ProjectDescription.FileListGlob.glob(Path(glob))
                                    }
                                ),
                                project: FileList.list(
                                    sourceGlobs.map { (glob: String) -> FileListGlob in
                                        ProjectDescription.FileListGlob.glob(
                                            Path(glob),
                                            excluding: (publicHeaderGlobs + privateHeaderGlobs).map { Path($0) }
                                        )
                                    }
                                )
                            )
                        }(),
                        dependencies: depenencies
                    )
                ],
                resourceSynthesizers: [.plists()]
            )
            externalDependencies[spec.name] = [
                .project(target: spec.name, path: manifestPath, condition: nil)
            ]
        }

        return (externalProjects, externalDependencies)
    }

    fileprivate func readSpecs(pathsProvider: CocoaPodsPathsProvider) throws -> [Podspec] {
        let specsDirectory = pathsProvider.destinationPodsDirectory.appending(component: "Podspecs")
        let files = try localFileSystem.getDirectoryContents(specsDirectory)
        
        var results: [Podspec] = []
        for file in files {
            let fileContent = try localFileSystem.readFileContents(specsDirectory.appending(component: file))
            try fileContent.withData { data in
                let podspec = try JSONDecoder().decode(Podspec.self, from: data)
                results.append(podspec)
            }
        }
        return results
    }

    // MARK: - Installation

    private func generateProjectSwiftFile(pathsProvider: CocoaPodsPathsProvider) throws {
        let projectSwiftFile = """
        import ProjectDescription

        let project = Project(
            name: "PodsHolder",
            targets: [
                Target(
                  name: "PodsHolder",
                  platform: .iOS,
                  product: .app,
                  bundleId: "io.tuist.PodsHolder",
                  infoPlist: .default,
                  sources: ["Sources/**"],
                  resources: [],
                  dependencies: []
                )
            ]
        )
        """

        try fileHandler.createFolder(pathsProvider.destinationCocoaPodsDirectory)
        try FileHandler.shared.write(
            projectSwiftFile,
            path: pathsProvider.destinationCocoaPodsDirectory.appending(component: "Project.swift"),
            atomically: true
        )
        try fileHandler.createFolder(pathsProvider.destinationCocoaPodsDirectory.appending(component: "Tuist"))

        var env = System.shared.env
        env["PATH"] = "/usr/local/bin:" + (env["PATH"] ?? "/usr/local/bin:/usr/bin:/bin")
        try System.shared.runAndPrint(
            ["/usr/bin/env", "tuist", "generate", "-p", pathsProvider.destinationCocoaPodsDirectory.pathString],
            verbose: true,
            environment: env
        )
    }

    private func generatePodfile(
        pathsProvider: CocoaPodsPathsProvider,
        dependencies: TuistGraph.CocoaPodsDependencies,
        platforms: Set<TuistGraph.PackagePlatform>
    ) throws {
        var podfile = """
        install! 'cocoapods', :warn_for_unused_master_specs_repo => false

        source 'ssh://gerrit.zhenguanyu.com:29418/ios-specs'
        source 'http://cocoapods.zhenguanyu.com/cdn/'

        platform :ios, '12.0'

        plugin 'cocoapods-show-podpsecs-in-project'

        inhibit_all_warnings!
        use_modular_headers!
        use_frameworks! :linkage => :static

        target 'PodsHolder' do

        """

        for dependency in dependencies.pods {
            switch dependency {
            case .remote(let name, let source, let subspecs):
                podfile += "  pod '\(name)', "

                switch source {
                case .version(let version):
                    podfile += "'\(version)'"
                case .podspec(let path):
                    podfile += ":podspec => '../../../\(path)'"
                case .gitWithTag(let source, let tag):
                    podfile += ":git => '\(source)', :tag => '\(tag)'"
                case .gitWithCommit(let source, let commit):
                    podfile += ":git => '\(source)', :commit => '\(commit)'"
                }

                if let subspecs {
                    let quoted = subspecs.map { "'\($0)'" }
                    podfile += ", :subspecs => [\(quoted.joined(separator: ", "))]"
                }

                podfile += "\n"
            }
        }

        podfile += "end\n"

        try FileHandler.shared.write(
            podfile,
            path: pathsProvider.temporaryPodfilePath,
            atomically: true
        )
    }

    /// Loads lockfile and dependencies into working directory if they had been saved before.
    private func loadDependencies(
        pathsProvider: CocoaPodsPathsProvider,
        dependencies: TuistGraph.CocoaPodsDependencies
    ) throws {
    }

    private func saveDependencies(pathsProvider: CocoaPodsPathsProvider) throws {
    }
}

// MARK: - Podspec Extensions

extension Podspec {
    func expandVendoredFramework(podsPath: AbsolutePath) -> [ProjectDescription.TargetDependency] {
        return (self.vendoredFrameworks ?? []).flatMap { glob -> [ProjectDescription.TargetDependency] in
            let pathString = podsPath
                .appending(component: self.name)
                .appending(try! RelativePath(validating: glob))
                .pathString

            if pathString.contains("*") {
                return Array(Glob(pattern: pathString))
                    .map { path in
                        if path.hasSuffix("xcframework") {
                            return .xcframework(path: Path(path), status: .required, condition: nil)
                        } else {
                            return .framework(path: Path(path), status: .required, condition: nil)
                        }
                    }
            } else {
                if pathString.hasSuffix("xcframework") {
                    return [.xcframework(path: Path(pathString), status: .required, condition: nil)]
                } else {
                    return [.framework(path: Path(pathString), status: .required, condition: nil)]
                }
            }
        }
    }
}

// MARK: - Models

private struct CocoaPodsPathsProvider {
    let dependenciesDirectory: AbsolutePath

    let destinationPodfilePath: AbsolutePath
    let destinationPodfileLockPath: AbsolutePath
    let destinationCocoaPodsDirectory: AbsolutePath
    let destinationPodsDirectory: AbsolutePath

    let temporaryPodfilePath: AbsolutePath
    let temporaryPodfileLockPath: AbsolutePath

    init(dependenciesDirectory: AbsolutePath) {
        self.dependenciesDirectory = dependenciesDirectory

        destinationPodfilePath = dependenciesDirectory
            .appending(component: Constants.DependenciesDirectory.lockfilesDirectoryName)
            .appending(component: Constants.DependenciesDirectory.podfileName)
        destinationPodfileLockPath = dependenciesDirectory
            .appending(component: Constants.DependenciesDirectory.lockfilesDirectoryName)
            .appending(component: Constants.DependenciesDirectory.podfileLockName)

        destinationCocoaPodsDirectory = dependenciesDirectory
            .appending(component: Constants.DependenciesDirectory.cocoaPodsDirectoryName)

        destinationPodsDirectory = destinationCocoaPodsDirectory
            .appending(component: Constants.DependenciesDirectory.podsDirectoryName)
        temporaryPodfilePath = destinationCocoaPodsDirectory
            .appending(component: Constants.DependenciesDirectory.podfileName)
        temporaryPodfileLockPath = destinationCocoaPodsDirectory
            .appending(component: Constants.DependenciesDirectory.podfileLockName)
    }
}
