//
//  CocoaPodspecData.swift
//  ProjectDescriptionHelpers
//
//  Created by zhangpeibj01 on 2022/7/29.
//

import Foundation

public struct Podspec: Decodable {

    public let rootspec: Subspec
    public let subspecs: [Subspec]?
    public let defaultSubspecs: [String]?
    public let version: String
    public let swiftVersion: String?
    public let cocoapodsVersion: String?
    public let prepareCommand: String?
    public let staticFramework: Bool?
    public let requiresAppHost: Bool?
    public let scheme: [String: Bool]?

    public var name: String { rootspec.name! }
    public var platforms: PodspecPlatform? { rootspec.platforms }
    public var dependencies: [String: ImplicitStringList]? { rootspec.dependencies }
    public var frameworks: [String]? { rootspec.frameworks }
    public var weakFrameworks: [String]? { rootspec.weakFrameworks }
    public var libraries: [String]? { rootspec.libraries }
    public var compilerFlags: [String]? { rootspec.compilerFlags }
    public var podTargetXcconfig: [String: ImplicitStringList]? { rootspec.podTargetXcconfig }
    public var userTargetXcconfig: [String: ImplicitStringList]? { rootspec.userTargetXcconfig }
    public var prefixHeaderFile: Bool? { rootspec.prefixHeaderFile }
    public var moduleName: String? { rootspec.moduleName }
    public var headerDir: String? { rootspec.headerDir }
    public var headerMappingsDir: String? { rootspec.headerMappingsDir }
    public var sourceFiles: [String]? { rootspec.sourceFiles }
    public var publicHeaderFiles: [String]? { rootspec.publicHeaderFiles }
    public var privateHeaderFiles: [String]? { rootspec.privateHeaderFiles }
    public var vendoredFrameworks: [String]? { rootspec.vendoredFrameworks }
    public var vendoredLibraries: [String]? { rootspec.vendoredLibraries }
    public var excludeFiles: [String]? { rootspec.excludeFiles }
    public var resourceBundles: [String: ImplicitStringList]? { rootspec.resourceBundles }
    public var resources: [String]? { rootspec.resources }
    public var preservePaths: [String]? { rootspec.preservePaths }
    public var moduleMap: String? { rootspec.moduleMap }
    public var requiresArc: BoolOrImplicitStringList? { rootspec.requiresArc }

    public var ios: Subspec? { rootspec.ios }
    public var osx: Subspec? { rootspec.osx }
    public var watchos: Subspec? { rootspec.watchos }
    public var tvos: Subspec? { rootspec.tvos }

    public init(
        rootspec: Subspec,
        version: String,
        subspecs: [Subspec]?,
        defaultSubspecs: [String]?,
        swiftVersion: String?,
        cocoapodsVersion: String?,
        prepareCommand: String?,
        staticFramework: Bool?,
        requiresAppHost: Bool?,
        scheme: [String: Bool]?
    ) {
        self.rootspec = rootspec
        self.version = version
        self.subspecs = subspecs
        self.defaultSubspecs = defaultSubspecs
        self.swiftVersion = swiftVersion
        self.cocoapodsVersion = cocoapodsVersion
        self.prepareCommand = prepareCommand
        self.staticFramework = staticFramework
        self.requiresAppHost = requiresAppHost
        self.scheme = scheme
    }

    public init(from decoder: any Decoder) throws {
        
        let singleValueContainer = try decoder.singleValueContainer()
        self.rootspec = try singleValueContainer.decode(Subspec.self)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.subspecs = try container.decodeIfPresent([Subspec].self, forKey: .subspecs)
        self.defaultSubspecs = try container.decode(ImplicitStringList.self, forKey: .defaultSubspecs).wrappedValue
        self.version = try container.decode(String.self, forKey: .version)
        self.swiftVersion = try container.decodeIfPresent(String.self, forKey: .swiftVersion)
        self.cocoapodsVersion = try container.decodeIfPresent(String.self, forKey: .cocoapodsVersion)
        self.prepareCommand = try container.decodeIfPresent(String.self, forKey: .prepareCommand)
        self.staticFramework = try container.decodeIfPresent(Bool.self, forKey: .staticFramework)
        self.scheme = try container.decodeIfPresent([String: Bool].self, forKey: .scheme)
        self.requiresAppHost = try container.decodeIfPresent(Bool.self, forKey: .requiresAppHost)
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case version
        case swiftVersion = "swift_version"
        case cocoapodsVersion = "cocoapods_version"
        case prepareCommand = "prepare_command"
        case staticFramework = "static_framework"
        case platforms
        case dependencies
        case frameworks
        case weakFrameworks = "weak_frameworks"
        case libraries
        case compilerFlags = "compiler_flags"
        case podTargetXcconfig = "pod_target_xcconfig"
        case userTargetXcconfig = "user_target_xcconfig"
        case prefixHeaderFile = "prefix_header_file"
        case moduleName = "module_name"
        case headerDir = "header_dir"
        case headerMappingsDir = "header_mappings_dir"
        case sourceFiles = "source_files"
        case publicHeaderFiles = "public_header_files"
        case privateHeaderFiles = "private_header_files"
        case vendoredFrameworks = "vendored_frameworks"
        case vendoredLibraries = "vendored_libraries"
        case resources
        case excludeFiles = "exclude_files"
        case preservePaths = "preserve_paths"
        case resourceBundles = "resource_bundles"
        case moduleMap = "module_map"
        case requiresAppHost = "requires_app_host"
        case scheme
        case defaultSubspecs = "default_subspecs"
        case ios
        case osx
        case watchos
        case tvos
        case subspecs
        case requiresArc = "requires_arc"
        case xcconfig
    }
}

import RegexBuilder

public extension Podspec {
    
    static func expandToValidGlob(from cocoapodsGlob: String) -> [String] {
        let regex = try! NSRegularExpression(pattern: "\\{(.+?)\\}")
        let nsrange = NSRange(cocoapodsGlob.startIndex..<cocoapodsGlob.endIndex, in: cocoapodsGlob)
        var results: [String] = []

        if let match = regex.firstMatch(in: cocoapodsGlob, options: [], range: nsrange) {
            let replaceRange = match.range(at: 0)
            let choices = (cocoapodsGlob as NSString).substring(with: match.range(at: 1))

            let choiceArray = choices.split(separator: ",")

            for choice in choiceArray {
                let newPath = (cocoapodsGlob as NSString).replacingCharacters(in: replaceRange, with: String(choice))
                results.append(newPath)
            }
        } else {
            results.append(cocoapodsGlob)
        }
        let validGlobs = results.filter { !$0.contains("{") }
        let cocoapodGlobs = results.filter { $0.contains("{") }
        let finalResults = validGlobs + cocoapodGlobs.flatMap { expandToValidGlob(from: $0) }
        let finalResultsWithStar = finalResults.map {
            if !$0.contains(".") && !$0.contains("*") {
                return ($0 + "/*").replacingOccurrences(of: "//", with: "/")
            } else {
                return $0
            }
        }
        return finalResultsWithStar
    }

    func resolveSubspecNames(selectedSubspecs: [String]?) -> [String] {
        let subspecs = subspecs ?? []
        var inspectedSubspecs: Set<String> = []
        var subspecsToInspect: [String] = selectedSubspecs ?? defaultSubspecs ?? subspecs.map { $0.name! }
        while !subspecsToInspect.isEmpty {
            let currentSubspecName = subspecsToInspect.popLast()!
            inspectedSubspecs.insert(currentSubspecName)
            if let currentSubspec = subspecs.first(where: { $0.name == currentSubspecName }) {
                for dependencyName in (currentSubspec.dependencies ?? [:]).keys where dependencyName.hasPrefix(self.name) {
                    let shortDependencyName = dependencyName.split(separator: "/")[1...].joined(separator: "/")
                    if !inspectedSubspecs.contains(shortDependencyName) {
                        subspecsToInspect.append(shortDependencyName)
                    }
                }
            } else {
                assertionFailure()
            }
        }
        return Array(inspectedSubspecs).sorted()
    }

    func resolvePodspec(selectedSubspecs: [String]?) -> Podspec {
        let subspecNames = self.resolveSubspecNames(selectedSubspecs: selectedSubspecs)
        let finalValidSubspecs = (self.subspecs ?? []).filter { subspecNames.contains($0.name!) }
        let mergedSpec = Subspec()
        mergedSpec.name = rootspec.name

        for subspec in ([self.rootspec] + finalValidSubspecs) {
            mergedSpec.merge(subspec)
        }

        mergedSpec.extractPlatformConfigs()

        mergedSpec.dependencies = mergedSpec.dependencies?.filter({ key, _ in
            return !key.hasPrefix(mergedSpec.name! + "/")
        })

        return Podspec(
            rootspec: mergedSpec,
            version: self.version,
            subspecs: self.subspecs,
            defaultSubspecs: self.defaultSubspecs,
            swiftVersion: self.swiftVersion,
            cocoapodsVersion: self.cocoapodsVersion,
            prepareCommand: self.prepareCommand,
            staticFramework: self.staticFramework,
            requiresAppHost: self.requiresAppHost,
            scheme: self.scheme
        )
    }

    var isAggregatePod: Bool {
        let noSource = (sourceFiles ?? []).isEmpty
        return noSource
    }
}

public struct PodspecPlatform: Decodable {
    public var ios: String?
    public var osx: String?
    public var watchos: String?
    public var tvos: String?
}
