import ProjectDescription
import TSCBasic
import TSCUtility
import TuistCore
import TuistGraph
import TuistSupport
import Foundation

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

        func convert(_ settingsDictionary: TuistGraph.SettingsDictionary) -> ProjectDescription.SettingsDictionary {
            settingsDictionary.mapValues {
                switch $0 {
                case .array(let array): return .array(array)
                case .string(let string): return .string(string)
                }
            }
        }

        let descriptionBaseSettings: ProjectDescription.SettingsDictionary = convert(dependencies.baseSettings.base)

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

        func expandVendoredFramework(spec: Podspec) -> [ProjectDescription.TargetDependency] {
            return spec.validVendoredFrameworks.flatMap { glob -> [ProjectDescription.TargetDependency] in
                let pathString = pathsProvider.destinationPodsDirectory
                    .appending(component: spec.name)
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

        for spec in specs {
            if isWrapperPod(spec) {
                externalDependencies[spec.name] = expandVendoredFramework(spec: spec)
            } else {
                let path = Path(pathsProvider.destinationPodsDirectory.appending(component: spec.name).pathString)

                var specSpecificConfigurations = descriptionConfigurations
                for (index, _) in specSpecificConfigurations.enumerated() {

                    if let settings = dependencies.targetSettings[spec.name] {
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
                        specSpecificConfigurations[index].settings["MODULEMAP_FILE"] = .string("../Target Support Files/\(spec.name)/\(spec.name).modulemap")
                    }
                }

                let sourceGlobs: [String] = spec.validSourceFiles.flatMap { cocoaPodsGlob in
                    Podspec.convertToGlob(from: cocoaPodsGlob)
                }

                let publicHeaderGlobs: [String] = {
                    if let headerFiles = spec.publicHeaderFiles {
                        return headerFiles.flatMap { headerFile in Podspec.convertToGlob(from: headerFile) } +
                            ["../Target Support Files/\(spec.name)/\(spec.name)-umbrella.h"]
                    } else {
                        return sourceGlobs +
                            ["../Target Support Files/\(spec.name)/\(spec.name)-umbrella.h"]
                    }
                }()

                let depenencies: [ProjectDescription.TargetDependency] = {
                    var result: [ProjectDescription.TargetDependency] = []

                    result += expandVendoredFramework(spec: spec)

                    result += spec.validLibraries.map {
                        .sdk(name: $0, type: .library, status: .required, condition: nil)
                    }

                    result += spec.validFrameworks.map {
                        .sdk(name: $0, type: .framework, status: .required, condition: nil)
                    }

                    result += spec.validDependenciesKeys.map { dependencyName in
                        if dependencyName.contains("/") {
                            // Convert subspec dependencies like "GTM/zlib" to "GTM"
                            return .external(name: String(dependencyName.split(separator: "/").first!))
                        } else {
                            return .external(name: dependencyName)
                        }
                    }

                    return result
                }()

                let shouldGenerateInfoPlist: Bool = spec.validVendoredFrameworks.contains(where: { $0.hasSuffix(".xcframework") })

                externalProjects[path] = ProjectDescription.Project(
                    name: spec.name,
                    settings: .settings(base: descriptionBaseSettings, configurations: specSpecificConfigurations),
                    targets: [
                        Target(
                            name: spec.name,
                            destinations: .iOS,
                            product: .staticFramework,
                            productName: spec.moduleName,
                            bundleId: "org.cocoapods.\(spec.name)".replacingOccurrences(of: "_", with: "-"),
                            infoPlist: shouldGenerateInfoPlist ? .default : .file(path: Path("../Target Support Files/\(spec.name)/\(spec.name)-Info.plist")),
                            sources: {
                                if !sourceGlobs.isEmpty {
                                    return ProjectDescription.SourceFilesList(globs: sourceGlobs.map { ProjectDescription.SourceFileGlob.glob(Path($0)) })
                                } else {
                                    return nil
                                }
                            }(),
                            headers: {
                                return ProjectDescription.Headers.headers(
                                    public: FileList.list(
                                        publicHeaderGlobs.map { (glob: String) -> FileListGlob in
                                            ProjectDescription.FileListGlob.glob(Path(glob))
                                        }
                                    ),
                                    private: [],
                                    project: FileList.list(
                                        sourceGlobs.map { (glob: String) -> FileListGlob in
                                            ProjectDescription.FileListGlob.glob(
                                                Path(glob),
                                                excluding: publicHeaderGlobs.map { Path($0) }
                                            )
                                        }
                                    )
                                )
                            }(),
                            dependencies: depenencies
                        )
                    ],
                    resourceSynthesizers: shouldGenerateInfoPlist ? [.plists()] : []
                )
                externalDependencies[spec.name] = [
                    .project(target: spec.name, path: path, condition: nil)
                ]
            }
        }
        return .init(externalDependencies: externalDependencies, externalProjects: externalProjects)
    }

    func isWrapperPod(_ spec: Podspec) -> Bool {
        let noSource = spec.validSourceFiles.isEmpty
        let hasVendoredFramework = !spec.validVendoredFrameworks.isEmpty
        let hasVendoredLibrary = !spec.validVendoredLibrary.isEmpty
        return noSource && (hasVendoredFramework || hasVendoredLibrary)
    }

    public func clean(dependenciesDirectory: AbsolutePath) throws {

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
