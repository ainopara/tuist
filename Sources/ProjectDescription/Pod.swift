import Foundation

public struct PodSpecSource: Codable, Equatable {
    public let name: String
    public let isCDN: Bool

    public init(name: String, isCDN: Bool) {
        self.name = name
        self.isCDN = isCDN
    }
}

public enum Pod: Equatable, Codable {
    case remote(
        name: String,
        source: PodSource,
        subspecs: [String]? = nil,
        generateModularHeaders: Bool = true
    )
}

public enum PodSource: Codable, Equatable {
    case version(String)
    case podspec(path: String)
}
