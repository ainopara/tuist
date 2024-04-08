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
    public var xcconfig: [String: ImplicitStringList]? { rootspec.xcconfig }

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

public extension Podspec {
    
    static func convertToGlob(from cocoapodsGlob: String) -> [String] {
        let regex = try! NSRegularExpression(pattern: "(.*)\\{(.+)\\}")
        let nsrange = NSRange(cocoapodsGlob.startIndex..<cocoapodsGlob.endIndex, in: cocoapodsGlob)
        var results: [String] = []

        if let match = regex.firstMatch(in: cocoapodsGlob, options: [], range: nsrange) {
            let basePath = (cocoapodsGlob as NSString).substring(with: match.range(at: 1))
            let extensions = (cocoapodsGlob as NSString).substring(with: match.range(at: 2))

            let extensionsArray = extensions.split(separator: ",")

            for ext in extensionsArray {
                let newPath = "\(basePath)\(ext)"
                results.append(newPath)
            }
        } else if !cocoapodsGlob.contains(".") && !cocoapodsGlob.contains("*") {
            results.append((cocoapodsGlob + "/*").replacingOccurrences(of: "//", with: "/"))
        } else {
            results.append(cocoapodsGlob)
        }
        return results
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
            return !key.hasPrefix(mergedSpec.name!)
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

    var validSourceFiles: [String] {
        var result: [String] = []
        result += self.sourceFiles ?? []
        result += self.ios?.sourceFiles ?? []
        if let subspecs = subspecs {
            for subspec in subspecs {
                result += subspec.validSourceFiles ?? []
            }
        }

        return result
    }

    var validRequiresArc: [String] {
        var result = [String]()
        if let requiresArc = requiresArc {
            switch requiresArc {
            case .bool(let isRequire) where isRequire :
                result.append(contentsOf: sourceFiles ?? [])
            case .implicitStringList(let list):
                result.append(contentsOf: list.wrappedValue ?? [])
            default:
                break
            }
        } else {
            result.append(contentsOf: sourceFiles ?? [])
        }
        if let subspecs = subspecs {
            for subspec in subspecs {
                result.append(contentsOf: subspec.validRequiresArc)
            }
        }
        return result
    }

    var validDependenciesKeys: [String] {
        var result = [String]()
        if let dependencies = dependencies {
            let keys = dependencies.keys
            result.append(contentsOf: Array(keys))
        }
        if let ios = ios {
            if let dependencies = ios.dependencies {
                let keys = dependencies.keys
                result.append(contentsOf: Array(keys))
            }
        }
        if let subspecs = subspecs {
            if let defaultSubspecs = defaultSubspecs {
                for subspec in subspecs where defaultSubspecs.contains(subspec.name!) {
                    result.append(contentsOf: subspec.validDependenciesKeys)
                }
            } else {
                for subspec in subspecs {
                    result.append(contentsOf: subspec.validDependenciesKeys)
                }
            }
        }
        result = Array(Set(result))
        return result.compactMap { dependency -> String? in
            if dependency.starts(with: name) {
                return nil
            } else if dependency.contains("/") {
                return dependency.components(separatedBy: "/").first
            } else {
                return dependency
            }
        }
    }

    var validFrameworks: [String] {
        var result: Set<String> = []
        result.formUnion(frameworks ?? [])
        result.formUnion(ios?.frameworks ?? [])
        if let subspecs = subspecs {
            let integratedSubspecs = defaultSubspecs ?? subspecs.map(\.name)
            for subspec in subspecs where integratedSubspecs.contains(subspec.name) {
                result.formUnion(subspec.frameworks ?? [])
            }
        }
        return Array(result).sorted()
    }

    var validWeakFrameworks: [String] {
        var result: Set<String> = []
        result.formUnion(weakFrameworks ?? [])
        if let subspecs = subspecs {
            let integratedSubspecs = defaultSubspecs ?? subspecs.map(\.name)
            for subspec in subspecs where integratedSubspecs.contains(subspec.name) {
                result.formUnion(subspec.weakFrameworks ?? [])
            }
        }
        return Array(result).sorted()
    }

    var validLibraries: [String] {
        var result: Set<String> = []
        result.formUnion(libraries ?? [])
        result.formUnion(ios?.libraries ?? [])
        if let subspecs = subspecs {
            let integratedSubspecs = defaultSubspecs ?? subspecs.map(\.name)
            for subspec in subspecs where integratedSubspecs.contains(subspec.name) {
                result.formUnion(subspec.libraries ?? [])
            }
        }
        return Array(result).sorted()
    }

    var validVendoredFrameworks: [String] {
        var result: Set<String> = []
        result.formUnion(vendoredFrameworks ?? [])
        result.formUnion(ios?.vendoredFrameworks ?? [])
        if let subspecs = subspecs {
            let integratedSubspecs = defaultSubspecs ?? subspecs.map(\.name)
            for subspec in subspecs where integratedSubspecs.contains(subspec.name) {
                result.formUnion(subspec.vendoredFrameworks ?? [])
            }
        }
        return Array(result).sorted()
    }

    var validVendoredLibrary: [String] {
        var result: Set<String> = []
        result.formUnion(vendoredLibraries ?? [])
        result.formUnion(ios?.vendoredFrameworks ?? [])
        if let subspecs = subspecs {
            let integratedSubspecs = defaultSubspecs ?? subspecs.map(\.name)
            for subspec in subspecs where integratedSubspecs.contains(subspec.name) {
                result.formUnion(subspec.vendoredLibraries ?? [])
            }
        }
        return Array(result).sorted()
    }

    var validPodTargetXcconfig: [String: ImplicitStringList] {
        var result: [String: ImplicitStringList] = [:]
        if let podTargetXcconfig = podTargetXcconfig {
            result = result.merging(podTargetXcconfig, uniquingKeysWith: { $1 })
        }
        if let xcconfig = xcconfig {
            result = result.merging(xcconfig, uniquingKeysWith: { $1 })
        }
        if let ios = ios {
            if let podTargetXcconfig = ios.podTargetXcconfig {
                result = result.merging(podTargetXcconfig, uniquingKeysWith: { $1 })
            }
        }
        if let subspecs = subspecs {
            if let defaultSubspecs = defaultSubspecs {
                for subspec in subspecs where defaultSubspecs.contains(subspec.name!) {
                    result = result.merging(subspec.validPodTargetXcconfig, uniquingKeysWith: { $1 })
                }
            } else {
                for subspec in subspecs {
                    result = result.merging(subspec.validPodTargetXcconfig, uniquingKeysWith: { $1 })
                }
            }
        }
        return result
    }

    var isWrapperPod: Bool {
        let noSource = validSourceFiles.isEmpty
        let hasVendoredFramework = !validVendoredFrameworks.isEmpty
        let hasVendoredLibrary = !validVendoredLibrary.isEmpty
        return noSource && (hasVendoredFramework || hasVendoredLibrary)
    }

    var isAggregatePod: Bool {
        let noSource = validSourceFiles.isEmpty
        return noSource
    }
}

// MARK: - consider subspec
public extension Podspec {
    func validFrameworksConsiderSubspec(subspecName: String? = nil) -> [String] {
        if let subspecName = subspecName {
            var result = [String]()
            if let frameworks = frameworks {
                result.append(contentsOf: frameworks)
            }
            if let ios = ios {
                if let frameworks = ios.frameworks {
                    result.append(contentsOf: frameworks)
                }
            }
            if let subspecs = subspecs {
                for subspec in subspecs where subspec.name == subspecName {
                    result.append(contentsOf: subspec.validFrameworks)
                }
            }
            return Array(Set(result))
        } else {
            return validFrameworks
        }
    }

    func validLibrariesConsiderSubspec(subspecName: String? = nil) -> [String] {
        if let subspecName = subspecName {
            var result = [String]()
            if let libraries = libraries {
                result.append(contentsOf: libraries)
            }
            if let ios = ios {
                if let libraries = ios.libraries {
                    result.append(contentsOf: libraries)
                }
            }
            if let subspecs = subspecs {
                for subspec in subspecs where subspec.name == subspecName {
                    result.append(contentsOf: subspec.validLibraries)
                }
            }
            return Array(Set(result))
        } else {
            return validLibraries
        }
    }

    func validDependenciesConsiderSubspec(subspecName: String? = nil) -> [String] {
        if let subspecName = subspecName {
            var result = [String]()
            if let dependencies = dependencies {
                let keys = dependencies.keys
                result.append(contentsOf: Array(keys))
            }
            if let ios = ios {
                if let dependencies = ios.dependencies {
                    let keys = dependencies.keys
                    result.append(contentsOf: Array(keys))
                }
            }
            if let subspecs = subspecs {
                for subspec in subspecs where subspec.name == subspecName {
                    result.append(contentsOf: subspec.validDependenciesKeys)
                }
            }
            result = Array(Set(result))
            return result.compactMap { dependency -> String? in
                if dependency.starts(with: name) {
                    return nil
                } else if dependency.contains("/") {
                    return dependency.components(separatedBy: "/").first
                } else {
                    return dependency
                }
            }
        } else {
            return validDependenciesKeys
        }
    }

    func validPodTargetXcconfigConsiderSubspec(subspecName: String? = nil) -> [String: ImplicitStringList] {
        if let subspecName = subspecName {
            var result: [String: ImplicitStringList] = [:]
            if let podTargetXcconfig = podTargetXcconfig {
                result = result.merging(podTargetXcconfig, uniquingKeysWith: { $1 })
            }
            if let xcconfig = xcconfig {
                result = result.merging(xcconfig, uniquingKeysWith: { $1 })
            }
            if let ios = ios {
                if let podTargetXcconfig = ios.podTargetXcconfig {
                    result = result.merging(podTargetXcconfig, uniquingKeysWith: { $1 })
                }
            }
            if let subspecs = subspecs {
                for subspec in subspecs where subspec.name == subspecName {
                    result = result.merging(subspec.validPodTargetXcconfig, uniquingKeysWith: { $1 })
                }
            }
            return result
        } else {
            return validPodTargetXcconfig
        }
    }
}

public struct PodspecPlatform: Decodable {
    public var ios: String?
    public var osx: String?
    public var watchos: String?
    public var tvos: String?
}


// MARK: - Decode Helper

public enum PodspecType {
    case json(String)
    case ruby(String)
}
