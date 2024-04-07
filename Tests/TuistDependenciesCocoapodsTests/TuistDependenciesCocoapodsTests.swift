//
//  File.swift
//  
//
//  Created by Zheng Li on 2024/4/7.
//

import Foundation
@testable import TuistDependencies
import XCTest

class TuistDependenciesCocoapodsTests: XCTestCase {

    func testPodspecParsing() throws {
        let specJSON = """
        {
          "name": "MobileQuickLogin",
          "version": "5.9.6",
          "summary": "Mobile Quick Login",
          "homepage": "https://wiki.zhenguanyu.com/iOS/Modules",
          "license": "Private",
          "authors": {
            "huangjx": "huangjx@fenbi.com"
          },
          "source": {
            "git": "ssh://gerrit.zhenguanyu.com:29418/ios-module-MobileQuickLogin",
            "tag": "5.9.6"
          },
          "platforms": {
            "ios": "8.0"
          },
          "vendored_frameworks": [
            "TYRZUISDK.framework"
          ],
          "resources": "TYRZResource.bundle",
          "pod_target_xcconfig": {
            "OTHER_LDFLAGS": [
              "-ObjC"
            ]
          },
          "weak_frameworks": "Network"
        }
        """
        let spec = try JSONDecoder().decode(Podspec.self, from: specJSON.data(using: .utf8)!)
        XCTAssertEqual(spec.name, "MobileQuickLogin")
        XCTAssertEqual(spec.version, "5.9.6")
        XCTAssertEqual(spec.platforms?.ios, "8.0")
        XCTAssertEqual(spec.vendoredFrameworks, ["TYRZUISDK.framework"])
        XCTAssertEqual(spec.resources, ["TYRZResource.bundle"])
        XCTAssertEqual(spec.podTargetXcconfig?["OTHER_LDFLAGS"]?.wrappedValue, ["-ObjC"])
        XCTAssertEqual(spec.weakFrameworks, ["Network"])
    }
}
