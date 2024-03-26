//
//  CocoaPodspecData.swift
//  ProjectDescriptionHelpers
//
//  Created by zhangpeibj01 on 2022/7/29.
//

import Foundation

public struct Podspec: Decodable {

    public let name: String
    public let version: String
    public let swiftVersion: String?
    public let cocoapodsVersion: String?
    public let prepareCommand: String?
    public let staticFramework: Bool?
    public let platforms: PodspecPlatform?
    public let dependencies: [String: ImplicitStringList]?
    @ImplicitStringList
    public var frameworks: [String]?
    public var weakFrameworks: String?
    @ImplicitStringList
    public var libraries: [String]?
    public let compilerFlags: String?
    public let podTargetXcconfig: [String: ImplicitStringList]?
    public let userTargetXcconfig: [String: ImplicitStringList]?
    public let prefixHeaderFile: Bool?
    public let moduleName: String?
    public let headerDir: String?
    public let headerMappingsDir: String?
    @ImplicitStringList
    public var sourceFiles: [String]?
    @ImplicitStringList
    public var publicHeaderFiles: [String]?
    @ImplicitStringList
    public var privateHeaderFiles: [String]?
    @ImplicitStringList
    public var vendoredFrameworks: [String]?
    @ImplicitStringList
    public var vendoredLibraries: [String]?
    public let resourceBundles: [String: ImplicitStringList]?
    @ImplicitStringList
    public var resources: [String]?
    @ImplicitStringList
    public var excludeFiles: [String]?
    @ImplicitStringList
    public var preservePaths: [String]?
    public let moduleMap: String?
    public let requiresAppHost: Bool?
    public let scheme: [String: Bool]?
    @ImplicitStringList
    public var defaultSubspecs: [String]?
    public let ios: PlatformConfig?
    public let osx: PlatformConfig?
    public let watchos: PlatformConfig?
    public let tvos: PlatformConfig?
    public let subspecs: [Subspec]?
    public let requiresArc: BoolOrImplicitStringList?
    public let xcconfig: [String: ImplicitStringList]?

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
    var validSourceFiles: [String]? {
        var result: [String] = []
        if let subspecs = subspecs {
            for subspec in subspecs {
                if let subspecValidSourceFiles = subspec.validSourceFiles {
                    result.append(contentsOf: subspecValidSourceFiles)
                }
            }
        }
        if let sourceFiles = sourceFiles {
            result.append(contentsOf: sourceFiles)
        }
        if
            let ios = ios,
            let files = ios.sourceFiles
        {
            result.append(contentsOf: files)
        }
        return result
    }

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
                for subspec in subspecs where defaultSubspecs.contains(subspec.name) {
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
            if let defaultSubspecs = defaultSubspecs {
                for subspec in subspecs where defaultSubspecs.contains(subspec.name) {
                    result.append(contentsOf: subspec.validFrameworks)
                }
            } else {
                for subspec in subspecs {
                    result.append(contentsOf: subspec.validFrameworks)
                }
            }
        }
        return Array(Set(result))
    }

    var validLibraries: [String] {
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
            if let defaultSubspecs = defaultSubspecs {
                for subspec in subspecs where defaultSubspecs.contains(subspec.name) {
                    result.append(contentsOf: subspec.validLibraries)
                }
            } else {
                for subspec in subspecs {
                    result.append(contentsOf: subspec.validLibraries)
                }
            }
        }
        return Array(Set(result))
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
                for subspec in subspecs where defaultSubspecs.contains(subspec.name) {
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

    var isArcheryTarget: Bool {
        return (vendoredLibraries != nil || ((vendoredFrameworks != nil || ios?.vendoredFrameworks != nil) && sourceFiles == nil))
    }
    
    var targetName: String {
        moduleName ?? name.replacingOccurrences(of: "-", with: "_")
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
    public let ios: String?
    public let osx: String?
    public let watchos: String?
    public let tvos: String?
}


// MARK: - Decode Helper

public enum PodspecType {
    case json(String)
    case ruby(String)
}
