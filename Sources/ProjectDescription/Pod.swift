import Foundation

public enum Pod: Equatable, Codable {
    case remote(name: String, source: PodSource, subspecs: [String]? = nil)
}

public enum PodSource: Codable, Equatable {
    case version(String)
    case podspec(path: String)
    case gitWithTag(source: String, tag: String)
    case gitWithCommit(source: String, commit: String)
}
