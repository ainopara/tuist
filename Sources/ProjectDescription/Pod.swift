import Foundation

public enum Pod: Equatable, Codable {
    case remote(name: String, source: PodSource)
    case local(path: Path)

    private enum Kind: String, Codable {
        case remote
        case local
    }
}

public enum PodSource: Codable, Equatable {
    case tag(String)
    case branch(String)
    case revision(String)
}
