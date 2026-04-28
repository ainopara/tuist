@testable import TuistDependencies
import XCTest

final class BundlerCommandTests: XCTestCase {
    func test_exec_usesBundleFromEnvironmentPath() {
        XCTAssertEqual(
            BundlerCommand.exec(["pod", "install"]),
            ["/usr/bin/env", "bundle", "exec", "pod", "install"]
        )
    }
}
