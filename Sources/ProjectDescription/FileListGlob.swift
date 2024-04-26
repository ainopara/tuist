import Foundation

/// A glob pattern that refers to files.
public struct FileListGlob: Codable, Equatable {
    /// The path with a glob pattern.
    public var glob: Path

    /// The excluding paths.
    public var excluding: [Path]

    public let isSingle: Bool

    /// Returns a generic file list glob.
    /// - Parameters:
    ///   - glob: The path with a glob pattern.
    ///   - excluding: The excluding paths.
    public static func glob(
        _ glob: Path,
        excluding: [Path] = []
    ) -> FileListGlob {
        FileListGlob(glob: glob, excluding: excluding, isSingle: false)
    }

    /// Returns a file list glob with an optional excluding path.
    public static func glob(
        _ glob: Path,
        excluding: Path?
    ) -> FileListGlob {
        FileListGlob(
            glob: glob,
            excluding: excluding.flatMap { [$0] } ?? [],
            isSingle: false
        )
    }

    public static func file(_ file: Path) -> FileListGlob {
        FileListGlob(glob: file, excluding: [], isSingle: true)
    }
}

extension FileListGlob: ExpressibleByStringInterpolation {
    public init(stringLiteral value: String) {
        self.init(glob: Path(value), excluding: [], isSingle: false)
    }
}
