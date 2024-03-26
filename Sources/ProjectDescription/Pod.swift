import Foundation

public enum Pod: Equatable, Codable {
    case remote(name: String, source: PodSource)
}

public enum PodSource: Codable, Equatable {
    case tag(String)
    case branch(String)
    case revision(String)
}
