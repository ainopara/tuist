//
//  File.swift
//  
//
//  Created by Zheng Li on 2022/8/10.
//

import Foundation

public struct PlatformConfig: Decodable {
    public let podTargetXcconfig: [String: ImplicitStringList]?
    public let dependencies: [String: ImplicitStringList]?
    @ImplicitStringList
    public var frameworks: [String]?
    @ImplicitStringList
    public var sourceFiles: [String]?
    @ImplicitStringList
    public var excludeFiles: [String]?
    @ImplicitStringList
    public var vendoredFrameworks: [String]?
    @ImplicitStringList
    public var libraries: [String]?

    private enum CodingKeys: String, CodingKey {
        case podTargetXcconfig = "pod_target_xcconfig"
        case dependencies
        case frameworks
        case sourceFiles = "source_files"
        case excludeFiles = "exclude_files"
        case vendoredFrameworks = "vendored_frameworks"
        case libraries
    }
}
