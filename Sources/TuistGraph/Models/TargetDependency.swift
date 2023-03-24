import Foundation
import TSCBasic

public enum SDKStatus: String, Codable {
    case required
    case optional
}

public enum PodDependencyType: String, Codable {
    case library
    case framework
}

public enum TargetDependency: Equatable, Hashable, Codable {
    case target(name: String)
    case project(target: String, path: AbsolutePath)
    case framework(path: AbsolutePath)
    case xcframework(path: AbsolutePath)
    case library(path: AbsolutePath, publicHeaders: AbsolutePath, swiftModuleMap: AbsolutePath?)
    case package(product: String)
    case sdk(name: String, status: SDKStatus)
    case xctest
    case cocoapod(type: PodDependencyType, content: String)
}
