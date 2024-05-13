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
        let specs = try fetchSpecs(pods: dependencies.pods, pathsProvider: pathsProvider)

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
        for case .remote(let name, _, let subpsecs, _, _) in dependencies.pods {
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

    // MARK: - Helpers

    func convert(_ settingsDictionary: TuistGraph.SettingsDictionary) -> ProjectDescription.SettingsDictionary {
        settingsDictionary.mapValues {
            switch $0 {
            case .array(let array): return .array(array)
            case .string(let string): return .string(string)
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

    func generateProjectDescription(
        for spec: Podspec,
        descriptionBaseSettings: ProjectDescription.SettingsDictionary,
        descriptionConfigurations: [ProjectDescription.Configuration],
        targetSettings: [String: TuistGraph.SettingsDictionary],
        podsDirectoryPath: AbsolutePath
    ) -> ([Path: ProjectDescription.Project], [String: [ProjectDescription.TargetDependency]]) {

        var externalProjects: [Path: ProjectDescription.Project] = [:]
        var externalDependencies: [String: [ProjectDescription.TargetDependency]] = [:]

        let manifestPath = Path(podsDirectoryPath.appending(component: spec.name).pathString)
        let sourceGlobs: [String] = (spec.sourceFiles ?? []).flatMap { cocoaPodsGlob in
            Podspec.expandToValidGlob(from: cocoaPodsGlob)
        }
        let sources = resolveGlobs(manifestPath: manifestPath, globs: sourceGlobs)
        let validSources = filterSources(sources, hasExtensionIn: Target.validSourceExtensions)

        let noSource = validSources.isEmpty
        let hasVendoredFramework = !(spec.vendoredFrameworks ?? []).isEmpty
        let hasVendoredLibrary = !(spec.vendoredLibraries ?? []).isEmpty
        let hasHeaderDir = !(spec.headerDir ?? "").isEmpty
        let isWrapperPod = noSource && (hasVendoredFramework || hasVendoredLibrary || hasHeaderDir)

        let shouldGenerateModuleMapAndUmbrellaHeader = !validSources.allSatisfy { $0.hasSuffix(".swift") }

        if isWrapperPod {
            var result = [ProjectDescription.TargetDependency]()
            result += spec.expandVendoredFramework(podsPath: podsDirectoryPath)
            result += spec.expandVendoredLibaray(podsPath: podsDirectoryPath)
            
            result += (spec.libraries ?? []) .map {
                .sdk(name: $0, type: .library, status: .required, condition: nil)
            }

            result += (spec.frameworks ?? []).map {
                .sdk(name: $0, type: .framework, status: .required, condition: nil)
            }

            result += (spec.weakFrameworks ?? []).map {
                .sdk(name: $0, type: .framework, status: .optional, condition: nil)
            }

            if spec.headerDir != nil {
                let path = podsDirectoryPath
                    .appending(component: "Headers")
                    .appending(component: "Public")
                    .appending(component: spec.name)
                result.append(.headerSearchPath(path: Path(path.pathString)))
                let rootPath = podsDirectoryPath
                    .appending(component: "Headers")
                    .appending(component: "Public")
                result.append(.headerSearchPath(path: Path(rootPath.pathString)))
            }

            externalDependencies[spec.name] = result
        } else {

            // MARK: - Configuration and Settings
            var specSpecificConfigurations = descriptionConfigurations
            for index in specSpecificConfigurations.indices {

                if let settings = targetSettings[spec.name] {
                    let convertedSettings = convert(settings)
                    for (key, value) in convertedSettings {
                        specSpecificConfigurations[index].settings[key] = value
                    }
                }

                if let moduleName = (spec.moduleName ?? spec.headerDir) {
                    specSpecificConfigurations[index].settings["PRODUCT_MODULE_NAME"] = .string(moduleName)
                }

                if let moduleMap = spec.moduleMap {
                    specSpecificConfigurations[index].settings["MODULEMAP_FILE"] = .string(moduleMap)
                } else if shouldGenerateModuleMapAndUmbrellaHeader {
                    let generatedModuleMapPath = try! AbsolutePath(
                        podsDirectoryPath,
                        RelativePath(validating: "Target Support Files/\(spec.name)/\(spec.name).modulemap")
                    )
                    if localFileSystem.exists(generatedModuleMapPath) {
                        specSpecificConfigurations[index].settings["MODULEMAP_FILE"] = .string("../Target Support Files/\(spec.name)/\(spec.name).modulemap")
                    }
                }

                if ["YTKRouterManager", "VGOWeb", "VGOFoundation", "VGOUIKit", "YTKCoreText", "ProtocolBuffers", "React-Core", "VGOCamera"].contains(spec.name) {
                    specSpecificConfigurations[index].settings["GCC_PREFIX_HEADER"] = .string("../Target Support Files/\(spec.name)/\(spec.name)-prefix.pch")
                }

                specSpecificConfigurations[index].settings["PODS_TARGET_SRCROOT"] = .string("${PODS_ROOT}/\(spec.name)")

                if let podTargetXcconfig = spec.podTargetXcconfig {
                    for (key, value) in podTargetXcconfig {
                        specSpecificConfigurations[index].settings = specSpecificConfigurations[index].settings
                            .applying(operation: .add(policy: .merge, settings: [key: .array(value.wrappedValue ?? [])]))
                    }
                }
                if let xcconfig = spec.rootspec.xcconfig {
                    for (key, value) in xcconfig {
                        specSpecificConfigurations[index].settings = specSpecificConfigurations[index].settings
                            .applying(operation: .add(policy: .merge, settings: [key: .array(value.wrappedValue ?? [])]))
                    }
                }
            }

            // MARK: - Compiler Flags

            var sharedCompilerFlags = spec.compilerFlags ?? []
            var customCompilerFlagsDictionary: [String: [String]] = [:]

            func compilerFlags(for filePath: String) -> [String] {
                if isSource(filePath, hasExtensionIn: ["s"]) { return [] }
                var result = sharedCompilerFlags + (customCompilerFlagsDictionary[filePath] ?? [])
                if isSource(filePath, hasExtensionIn: ["m", "mm", "c", "cpp", "cc"]) {
                    result += ["-w -Xanalyzer -analyzer-disable-all-checks"]
                }
                return result
            }

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

            // MARK: - Headers

            let privateHeaderGlobs: [String] = spec.privateHeaderFiles ?? []
            var privateHeaders = resolveGlobs(manifestPath: manifestPath, globs: privateHeaderGlobs)
            privateHeaders = filterSources(privateHeaders, hasExtensionIn: ["h", "hpp"])

            let publicHeaderGlobs: [String] = {
                var result: [String] = []
                if let headerFiles = spec.publicHeaderFiles {
                    result += headerFiles.flatMap { headerFile in Podspec.expandToValidGlob(from: headerFile) }
                } else {
                    result += sourceGlobs
                }
                if let headerDir = spec.headerDir {
                    result += Podspec.expandToValidGlob(from: headerDir)
                }
                if shouldGenerateModuleMapAndUmbrellaHeader {
                    result += ["../Target Support Files/\(spec.name)/\(spec.name)-umbrella.h"]
                }
                return result
            }()
            var publicHeaders: [String] = resolveGlobs(manifestPath: manifestPath, globs: publicHeaderGlobs)
                .filter { !privateHeaders.contains($0) }
            publicHeaders = filterSources(publicHeaders, hasExtensionIn: ["h", "hpp"])

            var projectHeaders = filterSources(sources, hasExtensionIn: ["h", "hpp"])
                .filter { !privateHeaders.contains($0) && !publicHeaders.contains($0) }

            var copyFileActions: [ProjectDescription.CopyFilesAction] = []

            if let headerMappingsDir = spec.headerMappingsDir {
                let generatorPaths = try! GeneratorPaths(manifestDirectory: AbsolutePath(validating: manifestPath.pathString))
                let headerMappingDirAbsolutePath = try! generatorPaths.resolve(path: Path(headerMappingsDir))
                let headersToPeserveFolderStructure = publicHeaders.filter { $0.hasPrefix(headerMappingDirAbsolutePath.pathString) }
                projectHeaders += headersToPeserveFolderStructure
                publicHeaders = publicHeaders.filter { !headersToPeserveFolderStructure.contains($0) }

                let headersGroupedByFolders = Dictionary(grouping: headersToPeserveFolderStructure, by: { filePath in
                    if let index = filePath.lastIndex(of: "/") {
                        let directoryPath = String(filePath[..<index])
                        return directoryPath
                    } else {
                        return ""
                    }
                })

                for (groupedFolder, headerFiles) in headersGroupedByFolders {
                    var relativeFolder = groupedFolder.replacingOccurrences(of: headerMappingDirAbsolutePath.pathString, with: "")
                    if relativeFolder.hasPrefix("/") {
                        relativeFolder.removeFirst()
                    }
                    copyFileActions.append(
                        .productsDirectory(
                            name: "Copy \(relativeFolder) Public Headers",
                            subpath: "$(PUBLIC_HEADERS_FOLDER_PATH)/\(relativeFolder)",
                            files: headerFiles.map { .glob(pattern: .relativeToRoot($0)) }
                        )
                    )
                }
            }

            // MARK: - Target Dependencies

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

            // MARK: - Target

            externalProjects[manifestPath] = ProjectDescription.Project(
                name: spec.name,
                settings: .settings(configurations: descriptionConfigurations.map {
                    switch $0.variant {
                    case .debug:
                        return .debug(name: $0.name)
                    case .release:
                        return .release(name: $0.name)
                    }
                }),
                targets: [
                    Target(
                        name: spec.name,
                        destinations: .iOS,
                        product: .staticFramework,
                        productName: validSources.isEmpty ? (spec.name + "Aggregate") : (spec.moduleName ?? spec.headerDir),
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
                        copyFiles: copyFileActions,
                        headers: {
                            return ProjectDescription.Headers.headers(
                                public: FileList.list(
                                    publicHeaders.map { ProjectDescription.FileListGlob.file(Path($0)) }
                                ),
                                private: FileList.list(
                                    privateHeaders.map { ProjectDescription.FileListGlob.file(Path($0)) }
                                ),
                                project: FileList.list(
                                    projectHeaders.map { ProjectDescription.FileListGlob.file(Path($0)) }
                                )
                            )
                        }(),
                        dependencies: depenencies,
                        settings: .settings(base: descriptionBaseSettings, configurations: specSpecificConfigurations)
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

    // MARK: - Fetch Podspecs

    private func fetchSpecs(pods: [CocoaPodsDependencies.Pod], pathsProvider: CocoaPodsPathsProvider) throws -> [Podspec] {
        
        let specsDirectory = pathsProvider.destinationCocoaPodsDirectory.appending(component: "Podspecs")
        try localFileSystem.removeFileTree(specsDirectory)
        try localFileSystem.createDirectory(specsDirectory)

        let savedCWD = localFileSystem.currentWorkingDirectory
        try localFileSystem.changeCurrentWorkingDirectory(to: specsDirectory)

        for pod in pods {
            switch pod {
            case .remote(let name, let source, _, _, _):
                switch source {
                case .version(let version):
                    try dealWithSourceVersion(pathsProvider: pathsProvider, name: name, version: version)
                case .podspec(let path):
                    try dealWithSourcePodspec(pathsProvider: pathsProvider, name: name, path: path)
                case .gitWithTag(let source, let tag):
                    logger.warning("Skipping fetch spec for \(source) \(tag)")
                    break
//                    dealWithSourceGit(name: name, source: source, checkoutName: tag)
                case .gitWithCommit(let source, let commit):
                    logger.warning("Skipping fetch spec for \(source) \(commit)")
                    break
//                    dealWithSourceGit(name: name, source: source, checkoutName: commit, isCommit: true)
                case .gitWithBranch(let source, let branch):
                    logger.warning("Skipping fetch spec for \(source) \(branch)")
                    break
//                    dealWithSourceGit(name: name, source: source, checkoutName: branch)
                }
            }
        }

        if let savedCWD {
            try localFileSystem.changeCurrentWorkingDirectory(to: savedCWD)
        }

        let files = try localFileSystem.getDirectoryContents(specsDirectory)
        var results: [Podspec] = []
        for file in files where file.hasSuffix(".json") {
            let fileContent = try localFileSystem.readFileContents(specsDirectory.appending(component: file))
            try fileContent.withData { data in
                let podspec = try JSONDecoder().decode(Podspec.self, from: data)
                results.append(podspec)
            }
        }
        return results
    }

    private func dealWithSourceVersion(pathsProvider: CocoaPodsPathsProvider, name: String, version: String) throws {

        func findSpecInSource(sourceName: String, isCDN: Bool) throws -> [AbsolutePath] {
            if isCDN {
                let specFolderPath = try AbsolutePath(validating: NSHomeDirectory() + "/.cocoapods/repos/\(sourceName)/Specs")
                let prefixPath = name.md5.prefix(3).map(String.init).joined(separator: "/")
                let jsonSpecPath = specFolderPath.appending(try RelativePath(validating: "\(prefixPath)/\(name)/\(version)/\(name).podspec.json"))
                let specPath = specFolderPath.appending(try RelativePath(validating: "\(prefixPath)/\(name)/\(version)/\(name).podspec"))
                return [jsonSpecPath, specPath]
            } else {
                let specFolderPath = try AbsolutePath(validating: NSHomeDirectory() + "/.cocoapods/repos/\(sourceName)")
                let jsonSpecPath = try specFolderPath.appending(RelativePath(validating: "\(name)/\(version)/\(name).podspec.json"))
                let specPath = try specFolderPath.appending(RelativePath(validating: "\(name)/\(version)/\(name).podspec"))
                return [jsonSpecPath, specPath]
            }
        }

        let sources = [
            ("zhenguanyu-cdn", true),
            ("zhenguanyu-ios-specs", false)
        ]

        var specPathCandidates: [AbsolutePath] = []
        for source in sources {
            let paths = try findSpecInSource(sourceName: source.0, isCDN: source.1)
            specPathCandidates += paths
        }

        guard let specPath = specPathCandidates.first(where: { localFileSystem.exists($0) }) else {
            logger.warning("Cannot find \(name).podspec.json in sources:")
            for candidate in specPathCandidates {
                logger.warning("  - \(candidate.pathString)")
            }
            return
        }

        let specsDirectory = pathsProvider.destinationCocoaPodsDirectory.appending(component: "Podspecs")
        try localFileSystem.copy(from: specPath, to: specsDirectory.appending(component: specPath.basename))
        if specPath.basename.hasSuffix(".podspec") {
            let result = try System.shared.capture(["bundle", "exec", "pod", "ipc", "spec", specPath.basename])
            let resultData = result.data(using: .utf8)!
            try localFileSystem.writeFileContents(
                specsDirectory.appending(component: specPath.basename + ".json"),
                bytes: ByteString(resultData),
                atomically: true
            )
        }
    }

    private func dealWithSourcePodspec(pathsProvider: CocoaPodsPathsProvider, name: String, path: String) throws {
        let projectRootPath = pathsProvider.dependenciesDirectory.parentDirectory.parentDirectory
        let specOrFolderPath = try projectRootPath.appending(RelativePath(validating: path))
        var specPath = specOrFolderPath
        if localFileSystem.isDirectory(specOrFolderPath) {
            specPath = specOrFolderPath.appending(component: "\(name).podspec.json")
            if !localFileSystem.exists(specPath) {
                specPath = specOrFolderPath.appending(component: "\(name).podspec")
            }
        }
        guard localFileSystem.exists(specPath) else {
            logger.warning("Cannot find \(name).podspec.json or \(name).podspec in \(path)")
            return
        }

        let specsDirectory = pathsProvider.destinationCocoaPodsDirectory.appending(component: "Podspecs")
        try localFileSystem.copy(from: specPath, to: specsDirectory.appending(component: specPath.basename))
        if specPath.basename.hasSuffix(".podspec") {
            let result = try System.shared.capture(["bundle", "exec", "pod", "ipc", "spec", specPath.basename])
            let resultData = result.data(using: .utf8)!
            try localFileSystem.writeFileContents(
                specsDirectory.appending(component: specPath.basename + ".json"),
                bytes: ByteString(resultData),
                atomically: true
            )
        }
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
            case .remote(let name, let source, let subspecs, let generateModularHeaders, _):
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
                case .gitWithBranch(let source, let branch):
                    podfile += ":git => '\(source)', :branch => '\(branch)'"
                }

                if let subspecs {
                    let quoted = subspecs.map { "'\($0)'" }
                    podfile += ", :subspecs => [\(quoted.joined(separator: ", "))]"
                }

                if !generateModularHeaders {
                    podfile += ", :modular_headers => false"
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

    func expandVendoredLibaray(podsPath: AbsolutePath) -> [ProjectDescription.TargetDependency] {
        return (self.vendoredLibraries ?? []).flatMap { glob -> [ProjectDescription.TargetDependency] in
            let pathString = podsPath
                .appending(component: self.name)
                .appending(try! RelativePath(validating: glob))
                .pathString

            let headerPath: Path = {
                if self.headerDir != nil {
                    return Path(
                        podsPath
                            .appending(component: "Headers")
                            .appending(component: "Public")
                            .appending(component: self.name)
                            .pathString
                    )
                } else {
                    return Path(
                        podsPath
                            .appending(component: "Headers")
                            .appending(component: "Public")
                            .pathString
                    )
                }
            }()

            if pathString.contains("*") {
                return Array(Glob(pattern: pathString))
                    .map { path in
                        return .library(path: Path(path), publicHeaders: headerPath, swiftModuleMap: nil)
                    }
            } else {
                return [.library(path: Path(pathString), publicHeaders: headerPath, swiftModuleMap: nil)]
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
