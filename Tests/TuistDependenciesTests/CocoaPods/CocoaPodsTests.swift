//
//  File.swift
//  
//
//  Created by Zheng Li on 2024/3/27.
//

import Foundation
import TuistSupportTesting
@testable import TuistDependencies

final class CocoaPodsTests: XCTestCase {

    func setUp() {
        super.setUp()
    }

    func tearDown() {
        super.tearDown()
    }

    func testGlobConvertion() {
        let cases = [
            "abc": ["abc/*"],
            "abc/**/*.{h,m}": ["abc/**/*.h", "abc/**/*.m"]
        ]

        for (input, output) in cases {
            XCTAssertEqual(Podspec.convertToGlob(from: input), output)
        }
    }
}
