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
        other.extractPlatformConfigs()
        if let otherPlatforms = other.platforms {
            if self.platforms == nil {
                self.platforms = other.platforms
            } else {
                self.platforms?.ios = otherPlatforms.ios
                self.platforms?.osx = otherPlatforms.osx
                self.platforms?.watchos = otherPlatforms.watchos
                self.platforms?.tvos = otherPlatforms.tvos
            }
        }
        if let otherModuleName = other.moduleName {
            self.moduleName = otherModuleName
        }
        if let otherModuleMap = other.moduleMap {
            self.moduleMap = otherModuleMap
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
        if let otherPublicHeaderFiles = other.publicHeaderFiles {
            let publicHeaderFiles = self.publicHeaderFiles ?? []
            self.publicHeaderFiles = publicHeaderFiles + otherPublicHeaderFiles.filter { !publicHeaderFiles.contains($0) }
        }
        if let otherPrivateHeaderFiles = other.privateHeaderFiles {
            let privateHeaderFiles = self.privateHeaderFiles ?? []
            self.privateHeaderFiles = privateHeaderFiles + otherPrivateHeaderFiles.filter { !privateHeaderFiles.contains($0) }
        }
        if let otherSourceFiles = other.sourceFiles {
            let sourceFiles = self.sourceFiles ?? []
            self.sourceFiles = sourceFiles + otherSourceFiles.filter { !sourceFiles.contains($0) }
        }

        if other.excludeFiles != nil {
            self.excludeFiles = (self.excludeFiles ?? []) + (other.excludeFiles ?? [])
        }
        if other.preservePaths != nil {
            self.preservePaths = (self.preservePaths ?? []) + (other.preservePaths ?? [])
        }

        if let otherRequiresArc = other.requiresArc {
            if let selfRequireArc = self.requiresArc {
                switch (selfRequireArc, otherRequiresArc) {
                case (.bool, .bool(let newValue)):
                    self.requiresArc = .bool(newValue)
                case (.bool(true), .array):
                    break
                case (.bool(false), .array(let newArray)):
                    self.requiresArc = .array(newArray)
                case (.array(_), .bool(let newValue)):
                    self.requiresArc = .bool(newValue)
                case (.array(let array1), .array(let array2)):
                    self.requiresArc = .array(Array(Set(array1 + array2)))
                }
            } else {
                self.requiresArc = otherRequiresArc
            }
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
        if other.podTargetXcconfig != nil {
            self.podTargetXcconfig = (self.podTargetXcconfig ?? [:]).merging(other.podTargetXcconfig ?? [:], uniquingKeysWith: {
                ImplicitStringList(wrappedValue: ($0.wrappedValue ?? []) + ($1.wrappedValue ?? []))
            })
        }
        if let otherUserTargetXcconfig = other.userTargetXcconfig {
            self.userTargetXcconfig = (self.userTargetXcconfig ?? [:]).merging(otherUserTargetXcconfig, uniquingKeysWith: {
                ImplicitStringList(wrappedValue: ($0.wrappedValue ?? []) + ($1.wrappedValue ?? []))
            })
        }
        if let otherCompilerFlags = other.compilerFlags {
            self.compilerFlags = (self.compilerFlags ?? []) + otherCompilerFlags
        }

        if let otherIOS = other.ios {
            self.ios?.merge(otherIOS)
        }
    }

    func extractPlatformConfigs() {
        if let ios = self.ios {
            merge(ios)
            self.ios = nil
        }
    }
}
