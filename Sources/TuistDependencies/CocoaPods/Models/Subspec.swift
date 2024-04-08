//
//  File.swift
//  
//
//  Created by Zheng Li on 2022/8/10.
//

import Foundation

public class Subspec: Decodable {

    public var name: String?

    public var platforms: PodspecPlatform?

    public var moduleName: String?
    public var moduleMap: String?
    public var prefixHeaderFile: Bool?
    public var headerDir: String?
    public var headerMappingsDir: String?
    @ImplicitStringList
    public var publicHeaderFiles: [String]?
    @ImplicitStringList
    public var privateHeaderFiles: [String]?
    @ImplicitStringList
    public var sourceFiles: [String]?
    @ImplicitStringList
    public var excludeFiles: [String]?
    @ImplicitStringList
    public var preservePaths: [String]?

    @ImplicitStringList
    public var resources: [String]?
    public var resourceBundles: [String: ImplicitStringList]?

    @ImplicitStringList
    public var frameworks: [String]?
    @ImplicitStringList
    public var weakFrameworks: [String]?
    @ImplicitStringList
    public var libraries: [String]?

    @ImplicitStringList
    public var vendoredFrameworks: [String]?
    @ImplicitStringList
    public var vendoredLibraries: [String]?

    public var dependencies: [String: ImplicitStringList]?

    public var xcconfig: [String: ImplicitStringList]?
    public var podTargetXcconfig: [String: ImplicitStringList]?
    public var userTargetXcconfig: [String: ImplicitStringList]?
    @ImplicitStringList
    public var compilerFlags: [String]?

    public var ios: Subspec?
    public var osx: Subspec?
    public var watchos: Subspec?
    public var tvos: Subspec?

    public var requiresArc: BoolOrImplicitStringList?
    public var subspecs: [Subspec]?

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

    func merge(_ other: Subspec) {
        if other.platforms != nil {
            if self.platforms == nil {
                self.platforms = other.platforms
            } else {
                self.platforms?.ios = other.platforms?.ios
                self.platforms?.osx = other.platforms?.osx
                self.platforms?.watchos = other.platforms?.watchos
                self.platforms?.tvos = other.platforms?.tvos
            }
        }
        if other.moduleName != nil {
            self.moduleName = other.moduleName
        }
        if other.moduleMap != nil {
            self.moduleMap = other.moduleMap
        }
        if other.prefixHeaderFile != nil {
            self.prefixHeaderFile = other.prefixHeaderFile
        }
        if other.headerDir != nil {
            self.headerDir = other.headerDir
        }
        if other.headerMappingsDir != nil {
            self.headerMappingsDir = other.headerMappingsDir
        }
        if other.publicHeaderFiles != nil {
            self.publicHeaderFiles = (self.publicHeaderFiles ?? []) + (other.publicHeaderFiles ?? [])
        }
        if other.privateHeaderFiles != nil {
            self.privateHeaderFiles = (self.privateHeaderFiles ?? []) + (other.privateHeaderFiles ?? [])
        }
        if other.sourceFiles != nil {
            self.sourceFiles = (self.sourceFiles ?? []) + (other.sourceFiles ?? [])
        }
        if other.excludeFiles != nil {
            self.excludeFiles = (self.excludeFiles ?? []) + (other.excludeFiles ?? [])
        }
        if other.preservePaths != nil {
            self.preservePaths = (self.preservePaths ?? []) + (other.preservePaths ?? [])
        }
        if other.resources != nil {
            self.resources = (self.resources ?? []) + (other.resources ?? [])
        }
        if other.resourceBundles != nil {
            self.resourceBundles = (self.resourceBundles ?? [:]).merging(other.resourceBundles ?? [:], uniquingKeysWith: { $1 })
        }
        if other.frameworks != nil {
            self.frameworks = (self.frameworks ?? []) + (other.frameworks ?? [])
        }
        if other.weakFrameworks != nil {
            self.weakFrameworks = (self.weakFrameworks ?? []) + (other.weakFrameworks ?? [])
        }
        if other.libraries != nil {
            self.libraries = (self.libraries ?? []) + (other.libraries ?? [])
        }
        if other.vendoredFrameworks != nil {
            self.vendoredFrameworks = (self.vendoredFrameworks ?? []) + (other.vendoredFrameworks ?? [])
        }
        if other.vendoredLibraries != nil {
            self.vendoredLibraries = (self.vendoredLibraries ?? []) + (other.vendoredLibraries ?? [])
        }
        if other.dependencies != nil {
            self.dependencies = (self.dependencies ?? [:]).merging(other.dependencies ?? [:], uniquingKeysWith: { $1 })
        }
        if other.xcconfig != nil {
            self.xcconfig = (self.xcconfig ?? [:]).merging(other.xcconfig ?? [:], uniquingKeysWith: {
                ImplicitStringList(wrappedValue: ($0.wrappedValue ?? []) + ($1.wrappedValue ?? []))
            })
        }
        if other.podTargetXcconfig != nil {
            self.podTargetXcconfig = (self.podTargetXcconfig ?? [:]).merging(other.podTargetXcconfig ?? [:], uniquingKeysWith: {
                ImplicitStringList(wrappedValue: ($0.wrappedValue ?? []) + ($1.wrappedValue ?? []))
            })
        }
        if other.userTargetXcconfig != nil {
            self.userTargetXcconfig = (self.userTargetXcconfig ?? [:]).merging(other.userTargetXcconfig ?? [:], uniquingKeysWith: {
                ImplicitStringList(wrappedValue: ($0.wrappedValue ?? []) + ($1.wrappedValue ?? []))
            })
        }
        if other.compilerFlags != nil {
            self.compilerFlags = (self.compilerFlags ?? []) + (other.compilerFlags ?? [])
        }

        if other.ios != nil {
            self.ios?.merge(other.ios!)
        }
    }

    func extractPlatformConfigs() {
        if let ios = self.ios {
            merge(ios)
            self.ios = nil
        }
    }

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
