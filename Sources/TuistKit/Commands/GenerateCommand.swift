import AnyCodable
import ArgumentParser
import Foundation
import TuistCore
import TuistSupport

public struct GenerateCommand: AsyncParsableCommand, HasTrackableParameters {
    public init() {}
    public static var analyticsDelegate: TrackableParametersDelegate?

    public static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "generate",
            abstract: "Generates an Xcode workspace to start working on the project.",
            subcommands: []
        )
    }

    @Option(
        name: .shortAndLong,
        help: "The path to the directory or a subdirectory of the project.",
        completion: .directory
    )
    var path: String?

    @Flag(
        name: .shortAndLong,
        help: "Open the project after generating it."
    )
    var open: Bool = false

    public func run() async throws {
        try await GenerateService().run(
            path: path,
            noOpen: !open
        )
    }
}
