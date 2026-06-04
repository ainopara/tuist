@testable import TuistDependencies
import Foundation
import XCTest

final class BundlerCommandTests: XCTestCase {
    func test_exec_usesBundleFromEnvironmentPath() {
        XCTAssertEqual(
            BundlerCommand.exec(["pod", "install"]),
            ["/usr/bin/env", "bundle", "exec", "pod", "install"]
        )
    }

    func test_cocoaPodsControllerEnvironmentPreservesCallerPath() {
        XCTAssertEqual(
            CocoaPodsController().defaultEnv["PATH"],
            ProcessInfo.processInfo.environment["PATH"]
        )
    }
}
