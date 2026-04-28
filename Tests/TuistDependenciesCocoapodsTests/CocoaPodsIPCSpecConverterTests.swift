@testable import TuistDependencies
import XCTest

final class CocoaPodsIPCSpecConverterTests: XCTestCase {
    func test_batches_preservesOrderAndLimitsBatchCount() {
        XCTAssertEqual(
            CocoaPodsIPCSpecConverter.batches(from: [1, 2, 3, 4, 5], maximumBatchCount: 2),
            [
                [1, 2, 3],
                [4, 5],
            ]
        )
    }

    func test_parseReplOutput_removesVersionOutputAndReturnsJSONChunks() throws {
        let output = "version: '1.16.2'\n\n\r\n" +
            #"{"name":"A"}"# + "\n\n\r\n" +
            #"{"name":"B"}"# + "\n\n\r\n"

        XCTAssertEqual(
            try CocoaPodsIPCSpecConverter.parseReplOutput(output, expectedOutputCount: 2),
            [
                #"{"name":"A"}"#,
                #"{"name":"B"}"#,
            ]
        )
    }

    func test_parseReplOutput_throwsWhenOutputCountDoesNotMatch() {
        XCTAssertThrowsError(
            try CocoaPodsIPCSpecConverter.parseReplOutput(#"{"name":"A"}"#, expectedOutputCount: 2)
        ) { error in
            XCTAssertEqual(error as? CocoaPodsIPCSpecConverterError, .unexpectedOutput(expected: 2, got: 1))
        }
    }
}
