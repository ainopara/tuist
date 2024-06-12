import TSCBasic
import TSCUtility
import TuistCore
import TuistGraph
import TuistSupport
import Foundation

// MARK: - CocoaPods Controlling

/// Protocol that defines an interface to interact with the CocoaPods.
public protocol CocoaPodsControlling {
    /// Checkouts and builds the project's dependencies
    /// - Parameters:
    ///   - path: Directory where project's dependencies will be installed.
    ///   - platforms: The platforms to build for.
    ///   - printOutput: When true it prints the CocoaPods's output.
    func install(at path: AbsolutePath, printOutput: Bool) throws

    /// Updates and rebuilds the project's dependencies
    /// - Parameters:
    ///   - path: Directory where project's dependencies will be installed.
    ///   - platforms: The platforms to build for.
    ///   - printOutput: When true it prints the CocoaPods's output.
    func update(at path: AbsolutePath, printOutput: Bool) throws
}

// MARK: - CocoaPods Controller

public final class CocoaPodsController: CocoaPodsControlling {
    /// Shared instance.
    public static var shared: CocoaPodsControlling = CocoaPodsController()

    var defaultEnv: [String: String] {
        var env = System.shared.env
        env["LANG"] = "en_US.UTF-8"
        env["PATH"] = "/usr/local/bin:" + (env["PATH"] ?? "/usr/local/bin:/usr/bin:/bin")
        return env
    }

    public func install(at path: AbsolutePath, printOutput: Bool) throws {

        let command = buildCocoaPodsCommand(path: path, subcommand: "install", arguments: [])

        if printOutput {
            try System.shared.runAndPrint(command, verbose: false, environment: defaultEnv)
        } else {
            _ = try System.shared.capture(command, verbose: false, environment: defaultEnv)
        }
    }

    public func update(at path: AbsolutePath, printOutput: Bool) throws {

        let command = buildCocoaPodsCommand(path: path, subcommand: "update")

        if printOutput {
            try System.shared.runAndPrint(command, verbose: false, environment: defaultEnv)
        } else {
            _ = try System.shared.capture(command, verbose: false, environment: defaultEnv)
        }
    }

    // MARK: - Helpers

    private func buildCocoaPodsCommand(path: AbsolutePath, subcommand: String, arguments: [String] = []) -> [String] {
        let commandComponents: [String] = [
            ("~/.rbenv/shims/bundle" as NSString).expandingTildeInPath,
            "exec",
            "pod",
            subcommand
        ]

        return commandComponents + arguments
    }
}
