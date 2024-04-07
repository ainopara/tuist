//
//  File.swift
//  
//
//  Created by Zheng Li on 2022/8/10.
//

import Foundation

public struct Subspec: Decodable {

    public let name: String
    @ImplicitStringList
    public var sourceFiles: [String]?
    public let platforms: PodspecPlatform?
    public let dependencies: [String: ImplicitStringList]?
    @ImplicitStringList
    public var frameworks: [String]?
    @ImplicitStringList
    public var libraries: [String]?
    @ImplicitStringList
    public var privateHeaderFiles: [String]?
    @ImplicitStringList
    public var excludeFiles: [String]?
    public let xcconfig: [String: ImplicitStringList]?
    @ImplicitStringList
    public var compilerFlags: [String]?
    @ImplicitStringList
    public var publicHeaderFiles: [String]?
    public let ios: PlatformConfig?
    public let osx: PlatformConfig?
    public let watchos: PlatformConfig?
    public let tvos: PlatformConfig?
    @ImplicitStringList
    public var vendoredFrameworks: [String]?
    @ImplicitStringList
    public var vendoredLibraries: [String]?
    @ImplicitStringList
    public var weakFrameworks: [String]?
    public let podTargetXcconfig: [String: ImplicitStringList]?
    public let subspecs: [Subspec]?
    public let requiresArc: BoolOrImplicitStringList?
    public var userTargetXcconfig: [String: ImplicitStringList]?
    public var prefixHeaderFile: Bool?
    public var moduleName: String?
    public var headerDir: String?
    public var headerMappingsDir: String?
    public var resourceBundles: [String: ImplicitStringList]?
    @ImplicitStringList
    public var resources: [String]?
    @ImplicitStringList
    public var preservePaths: [String]?
    public var moduleMap: String?

    private enum CodingKeys: String, CodingKey {
        case name
        case sourceFiles = "source_files"
        case platforms
        case dependencies
        case frameworks
        case libraries
        case privateHeaderFiles = "private_header_files"
        case excludeFiles = "exclude_files"
        case xcconfig
        case publicHeaderFiles = "public_header_files"
        case ios
        case osx
        case watchos
        case tvos
        case vendoredFrameworks = "vendored_frameworks"
        case vendoredLibraries = "vendored_libraries"
        case weakFrameworks = "weak_frameworks"
        case podTargetXcconfig = "pod_target_xcconfig"
        case subspecs
        case requiresArc = "requires_arc"
        case compilerFlags = "compiler_flags"
        case userTargetXcconfig = "user_target_xcconfig"
        case prefixHeaderFile = "prefix_header_file"
        case moduleName = "module_name"
        case headerDir = "header_dir"
        case headerMappingsDir = "header_mappings_dir"
        case preservePaths = "preserve_paths"
        case resourceBundles = "resource_bundles"
        case resources
        case moduleMap
    }
}

public extension Subspec {

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
            for subspec in subspecs {
                result.append(contentsOf: subspec.validDependenciesKeys)
            }
        }
        return Array(Set(result))
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
            for subspec in subspecs {
                result.append(contentsOf: subspec.validFrameworks)
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
            for subspec in subspecs {
                result.append(contentsOf: subspec.validLibraries)
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
            for subspec in subspecs {
                result = result.merging(subspec.validPodTargetXcconfig, uniquingKeysWith: { $1 })
            }
        }

        return result
    }
}
