//
//  File.swift
//  
//
//  Created by Zheng Li on 2024/4/7.
//

import Foundation
@testable import TuistDependencies
import XCTest
import TSCBasic
import ProjectDescription
import CustomDump

class TuistDependenciesCocoapodsTests: XCTestCase {

    func testPodspecParsingMobileQuickLogin() throws {
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

        let (project, dependencies) = CocoaPodsInteractor().generateProjectDescription(
            for: spec,
            descriptionBaseSettings: [:],
            descriptionConfigurations: [],
            targetSettings: [:],
            podsDirectoryPath: AbsolutePath("/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods")
        )

        XCTAssertNoDifference(spec.name, "MobileQuickLogin")
        XCTAssertNoDifference(spec.version, "5.9.6")
        XCTAssertNoDifference(spec.platforms?.ios, "8.0")
        XCTAssertNoDifference(spec.vendoredFrameworks, ["TYRZUISDK.framework"])
        XCTAssertNoDifference(spec.resources, ["TYRZResource.bundle"])
        XCTAssertNoDifference(spec.podTargetXcconfig?["OTHER_LDFLAGS"]?.wrappedValue, ["-ObjC"])
        XCTAssertNoDifference(spec.weakFrameworks, ["Network"])
        XCTAssertNoDifference(project, [:])
        XCTAssertNoDifference(
            dependencies,
            [
                "MobileQuickLogin": [
                    ProjectDescription.TargetDependency.framework(
                        path: Path("/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MobileQuickLogin/TYRZUISDK.framework"),
                        status: .required,
                        condition: nil
                    ),
                    ProjectDescription.TargetDependency.sdk(
                        name: "Network",
                        type: .framework,
                        status: .optional,
                        condition: nil
                    )
                ]
            ]
        )
    }

    func testPodspecParsingTensorFlowLiteC() throws {
        let specJSON = """
        {
          "name": "TensorFlowLiteC",
          "version": "2.7.0",
          "authors": "Google Inc.",
          "license": {
            "type": "Apache"
          },
          "homepage": "https://github.com/tensorflow/tensorflow",
          "source": {
            "http": "https://dl.google.com/dl/cpdc/6ffa58c2d5bbf5ff/TensorFlowLiteC-2.7.0.tar.gz"
          },
          "summary": "TensorFlow Lite",
          "description": "An internal-only pod containing the TensorFlow Lite C library that the public\n`TensorFlowLiteSwift` and `TensorFlowLiteObjC` pods depend on. This pod is not\nintended to be used directly. Swift developers should use the\n`TensorFlowLiteSwift` pod and Objective-C developers should use the\n`TensorFlowLiteObjC` pod.",
          "platforms": {
            "ios": "9.0"
          },
          "module_name": "TensorFlowLiteC",
          "libraries": "c++",
          "default_subspecs": "Core",
          "subspecs": [
            {
              "name": "Core",
              "vendored_frameworks": "Frameworks/TensorFlowLiteC.framework"
            },
            {
              "name": "CoreML",
              "weak_frameworks": "CoreML",
              "dependencies": {
                "TensorFlowLiteC/Core": [

                ]
              },
              "vendored_frameworks": "Frameworks/TensorFlowLiteCCoreML.framework"
            },
            {
              "name": "Metal",
              "weak_frameworks": "Metal",
              "dependencies": {
                "TensorFlowLiteC/Core": [

                ]
              },
              "vendored_frameworks": "Frameworks/TensorFlowLiteCMetal.framework"
            }
          ]
        }
        """
        var spec = try JSONDecoder().decode(Podspec.self, from: specJSON.data(using: .utf8)!)
        spec = spec.resolvePodspec(selectedSubspecs: nil)

        let (project, dependencies) = CocoaPodsInteractor().generateProjectDescription(
            for: spec,
            descriptionBaseSettings: [:],
            descriptionConfigurations: [],
            targetSettings: [:],
            podsDirectoryPath: AbsolutePath("/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods")
        )



        XCTAssertNoDifference(spec.name, "TensorFlowLiteC")
        XCTAssertNoDifference(spec.version, "2.7.0")
        XCTAssertNoDifference(spec.platforms?.ios, "9.0")
        XCTAssertNoDifference(spec.moduleName, "TensorFlowLiteC")
        XCTAssertNoDifference(spec.libraries, ["c++"])
        XCTAssertNoDifference(spec.defaultSubspecs, ["Core"])

        XCTAssertNoDifference(project, [:])
        XCTAssertNoDifference(
            dependencies,
            [
                "TensorFlowLiteC": [
                    ProjectDescription.TargetDependency.framework(
                        path: Path("/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/TensorFlowLiteC/Frameworks/TensorFlowLiteC.framework"),
                        status: .required,
                        condition: nil
                    ),
                    ProjectDescription.TargetDependency.sdk(
                        name: "c++",
                        type: .library,
                        status: .required,
                        condition: nil
                    )
                ]
            ]
        )
    }

    func testPodspecResolveSubspecNames() throws {
        let specJSON = """
        {
          "name": "TensorFlowLiteC",
          "version": "2.7.0",
          "authors": "Google Inc.",
          "license": {
            "type": "Apache"
          },
          "homepage": "https://github.com/tensorflow/tensorflow",
          "source": {
            "http": "https://dl.google.com/dl/cpdc/6ffa58c2d5bbf5ff/TensorFlowLiteC-2.7.0.tar.gz"
          },
          "summary": "TensorFlow Lite",
          "description": "An internal-only pod containing the TensorFlow Lite C library that the public\n`TensorFlowLiteSwift` and `TensorFlowLiteObjC` pods depend on. This pod is not\nintended to be used directly. Swift developers should use the\n`TensorFlowLiteSwift` pod and Objective-C developers should use the\n`TensorFlowLiteObjC` pod.",
          "platforms": {
            "ios": "9.0"
          },
          "module_name": "TensorFlowLiteC",
          "libraries": "c++",
          "default_subspecs": "Core",
          "subspecs": [
            {
              "name": "Core",
              "vendored_frameworks": "Frameworks/TensorFlowLiteC.framework"
            },
            {
              "name": "CoreML",
              "weak_frameworks": "CoreML",
              "dependencies": {
                "TensorFlowLiteC/Core": [

                ]
              },
              "vendored_frameworks": "Frameworks/TensorFlowLiteCCoreML.framework"
            },
            {
              "name": "Metal",
              "weak_frameworks": "Metal",
              "dependencies": {
                "TensorFlowLiteC/Core": [

                ]
              },
              "vendored_frameworks": "Frameworks/TensorFlowLiteCMetal.framework"
            }
          ]
        }
        """
        let spec = try JSONDecoder().decode(Podspec.self, from: specJSON.data(using: .utf8)!)

        XCTAssertNoDifference(spec.resolveSubspecNames(selectedSubspecs: nil), ["Core"])
        XCTAssertNoDifference(spec.resolveSubspecNames(selectedSubspecs: ["Core"]), ["Core"])
        XCTAssertNoDifference(spec.resolveSubspecNames(selectedSubspecs: ["Metal"]), ["Core", "Metal"])
        XCTAssertNoDifference(spec.resolveSubspecNames(selectedSubspecs: ["CoreML"]), ["Core", "CoreML"])
        XCTAssertNoDifference(spec.resolveSubspecNames(selectedSubspecs: ["Metal", "CoreML"]), ["Core", "CoreML", "Metal"])
    }

    func testPodspecResolve() throws {
        let specJSON = """
        {
          "name": "TensorFlowLiteC",
          "version": "2.7.0",
          "authors": "Google Inc.",
          "license": {
            "type": "Apache"
          },
          "homepage": "https://github.com/tensorflow/tensorflow",
          "source": {
            "http": "https://dl.google.com/dl/cpdc/6ffa58c2d5bbf5ff/TensorFlowLiteC-2.7.0.tar.gz"
          },
          "summary": "TensorFlow Lite",
          "description": "An internal-only pod containing the TensorFlow Lite C library that the public\n`TensorFlowLiteSwift` and `TensorFlowLiteObjC` pods depend on. This pod is not\nintended to be used directly. Swift developers should use the\n`TensorFlowLiteSwift` pod and Objective-C developers should use the\n`TensorFlowLiteObjC` pod.",
          "platforms": {
            "ios": "9.0"
          },
          "module_name": "TensorFlowLiteC",
          "libraries": "c++",
          "default_subspecs": "Core",
          "subspecs": [
            {
              "name": "Core",
              "vendored_frameworks": "Frameworks/TensorFlowLiteC.framework"
            },
            {
              "name": "CoreML",
              "weak_frameworks": "CoreML",
              "dependencies": {
                "TensorFlowLiteC/Core": [

                ]
              },
              "vendored_frameworks": "Frameworks/TensorFlowLiteCCoreML.framework"
            },
            {
              "name": "Metal",
              "weak_frameworks": "Metal",
              "dependencies": {
                "TensorFlowLiteC/Core": [

                ]
              },
              "vendored_frameworks": "Frameworks/TensorFlowLiteCMetal.framework"
            }
          ]
        }
        """
        let spec = try JSONDecoder().decode(Podspec.self, from: specJSON.data(using: .utf8)!)
        let newSpec = spec.resolvePodspec(selectedSubspecs: ["Metal", "CoreML"])

        XCTAssertNoDifference(newSpec.name, "TensorFlowLiteC")
        XCTAssertNoDifference(newSpec.version, "2.7.0")
        XCTAssertNoDifference(newSpec.platforms?.ios, "9.0")
        XCTAssertNoDifference(newSpec.moduleName, "TensorFlowLiteC")
        XCTAssertNoDifference(newSpec.libraries, ["c++"])
        XCTAssertNoDifference(newSpec.defaultSubspecs, ["Core"])
        XCTAssertNoDifference(newSpec.weakFrameworks, ["CoreML", "Metal"])
        XCTAssertNoDifference(newSpec.vendoredFrameworks, [
            "Frameworks/TensorFlowLiteC.framework",
            "Frameworks/TensorFlowLiteCCoreML.framework",
            "Frameworks/TensorFlowLiteCMetal.framework"
        ])
    }

    func testPodspecMergeDeduplication() throws {
        let specJSON = """
        {
          "name": "Sentry",
          "version": "8.9.0-beta.1",
          "summary": "Sentry client for cocoa",
          "homepage": "https://github.com/getsentry/sentry-cocoa",
          "license": "mit",
          "authors": "Sentry",
          "source": {
            "git": "https://github.com/getsentry/sentry-cocoa.git",
            "tag": "8.9.0-beta.1"
          },
          "platforms": {
            "ios": "11.0",
            "osx": "10.13",
            "tvos": "11.0",
            "watchos": "4.0"
          },
          "module_name": "Sentry",
          "requires_arc": true,
          "frameworks": "Foundation",
          "libraries": [
            "z",
            "c++"
          ],
          "swift_versions": "5.5",
          "pod_target_xcconfig": {
            "GCC_ENABLE_CPP_EXCEPTIONS": "YES",
            "CLANG_CXX_LANGUAGE_STANDARD": "c++14",
            "CLANG_CXX_LIBRARY": "libc++"
          },
          "watchos": {
            "pod_target_xcconfig": {
              "OTHER_LDFLAGS": "$(inherited) -framework WatchKit"
            }
          },
          "default_subspecs": [
            "Core"
          ],
          "dependencies": {
            "SentryPrivate": [
              "8.9.0-beta.1"
            ]
          },
          "subspecs": [
            {
              "name": "Core",
              "source_files": [
                "Sources/Sentry/**/*.{h,hpp,m,mm,c,cpp}",
                "Sources/SentryCrash/**/*.{h,hpp,m,mm,c,cpp}",
                "Sources/Swift/Sentry.swift"
              ],
              "public_header_files": "Sources/Sentry/Public/*.h"
            },
            {
              "name": "HybridSDK",
              "source_files": [
                "Sources/Sentry/**/*.{h,hpp,m,mm,c,cpp}",
                "Sources/SentryCrash/**/*.{h,hpp,m,mm,c,cpp}",
                "Sources/Swift/Sentry.swift"
              ],
              "public_header_files": [
                "Sources/Sentry/Public/*.h",
                "Sources/Sentry/include/HybridPublic/*.h"
              ]
            }
          ],
          "swift_version": "5.5"
        }
        """

        var spec = try JSONDecoder().decode(Podspec.self, from: specJSON.data(using: .utf8)!)
        spec = spec.resolvePodspec(selectedSubspecs: ["Core", "HybridSDK"])

        let (project, dependencies) = CocoaPodsInteractor().generateProjectDescription(
            for: spec,
            descriptionBaseSettings: [:],
            descriptionConfigurations: [],
            targetSettings: [:],
            podsDirectoryPath: AbsolutePath("/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods")
        )

        XCTAssertNoDifference(spec.name, "Sentry")
        XCTAssertNoDifference(spec.version, "8.9.0-beta.1")
        XCTAssertNoDifference(spec.platforms?.ios, "11.0")
        XCTAssertNoDifference(spec.publicHeaderFiles, [
            "Sources/Sentry/Public/*.h",
            "Sources/Sentry/include/HybridPublic/*.h"
        ])
        XCTAssertNoDifference(spec.sourceFiles, [
            "Sources/Sentry/**/*.{h,hpp,m,mm,c,cpp}",
            "Sources/SentryCrash/**/*.{h,hpp,m,mm,c,cpp}",
            "Sources/Swift/Sentry.swift"
        ])
        XCTAssertNoDifference(Array((spec.dependencies ?? [:]).keys).sorted() , [
            "SentryPrivate"
        ])
    }

    func testPodspecObjcHeaderSearch() throws {
        let specJSON = """
        {
          "name": "CocoaLumberjack",
          "version": "3.7.4",
          "license": "BSD",
          "summary": "A fast & simple, yet powerful & flexible logging framework for macOS, iOS, tvOS and watchOS.",
          "homepage": "https://github.com/CocoaLumberjack/CocoaLumberjack",
          "authors": {
            "Robbie Hanson": "robbiehanson@deusty.com"
          },
          "source": {
            "git": "https://github.com/CocoaLumberjack/CocoaLumberjack.git",
            "tag": "3.7.4"
          },
          "description": "It is similar in concept to other popular logging frameworks such as log4j, yet is designed specifically for objective-c, and takes advantage of features such as multi-threading, grand central dispatch (if available), lockless atomic operations, and the dynamic nature of the objective-c runtime.",
          "preserve_paths": "README.md",
          "platforms": {
            "ios": "9.0",
            "osx": "10.10",
            "watchos": "3.0",
            "tvos": "9.0"
          },
          "cocoapods_version": ">= 1.4.0",
          "requires_arc": true,
          "swift_versions": "5.0",
          "default_subspecs": "Core",
          "subspecs": [
            {
              "name": "Core",
              "source_files": "Sources/CocoaLumberjack/**/*.{h,m}",
              "private_header_files": "Sources/CocoaLumberjack/DD*Internal.{h}"
            },
            {
              "name": "Swift",
              "dependencies": {
                "CocoaLumberjack/Core": [

                ]
              },
              "source_files": [
                "Sources/CocoaLumberjackSwift/**/*.swift",
                "Sources/CocoaLumberjackSwiftSupport/include/**/*.{h}"
              ]
            }
          ],
          "swift_version": "5.0"
        }

        """

        var spec = try JSONDecoder().decode(Podspec.self, from: specJSON.data(using: .utf8)!)
        spec = spec.resolvePodspec(selectedSubspecs: ["Core", "Swift"])

        let (project, dependencies) = CocoaPodsInteractor().generateProjectDescription(
            for: spec,
            descriptionBaseSettings: [:],
            descriptionConfigurations: [],
            targetSettings: [:],
            podsDirectoryPath: AbsolutePath("/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods")
        )

        XCTAssertNoDifference(spec.name, "CocoaLumberjack")
        XCTAssertNoDifference(spec.privateHeaderFiles, [
            "Sources/CocoaLumberjack/DD*Internal.{h}"
        ])
        XCTAssertNoDifference(spec.sourceFiles, [
            "Sources/CocoaLumberjack/**/*.{h,m}",
            "Sources/CocoaLumberjackSwift/**/*.swift",
            "Sources/CocoaLumberjackSwiftSupport/include/**/*.{h}"
        ])
        XCTAssertNoDifference(Array((spec.dependencies ?? [:]).keys).sorted() , [])
    }
}
