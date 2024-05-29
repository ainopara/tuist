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

    func testConvertToGlob() {
        XCTAssertNoDifference(
            Podspec.expandToValidGlob(from: "ReactCommon"),
            [
                "ReactCommon/*",
            ]
        )
        XCTAssertNoDifference(
            Podspec.expandToValidGlob(from: "ReactCommon/yoga/yoga/{Yoga,YGEnums,YGMacros,YGNode,YGStyle,YGValue}.h"),
            [
                "ReactCommon/yoga/yoga/Yoga.h",
                "ReactCommon/yoga/yoga/YGEnums.h",
                "ReactCommon/yoga/yoga/YGMacros.h",
                "ReactCommon/yoga/yoga/YGNode.h",
                "ReactCommon/yoga/yoga/YGStyle.h",
                "ReactCommon/yoga/yoga/YGValue.h"
            ]
        )
        XCTAssertNoDifference(
            Podspec.expandToValidGlob(from: "ReactCommon/yoga/yoga/*.{h,m}"),
            [
                "ReactCommon/yoga/yoga/*.h",
                "ReactCommon/yoga/yoga/*.m"
            ]
        )
        XCTAssertNoDifference(
            Podspec.expandToValidGlob(from: "AFNetworking/AF{URL,HTTP}SessionManager.{h,m}"),
            [
                "AFNetworking/AFURLSessionManager.h",
                "AFNetworking/AFURLSessionManager.m",
                "AFNetworking/AFHTTPSessionManager.h",
                "AFNetworking/AFHTTPSessionManager.m"
            ]
        )

    }

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

        let (projects, dependencies) = CocoaPodsInteractor().generateProjectDescription(
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
        XCTAssertNoDifference(projects, [:])
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
                    ),
                    ProjectDescription.TargetDependency.bundle(
                        path: Path(
                            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MobileQuickLogin/TYRZResource.bundle/"
                        )
                    )
                ]
            ]
        )
    }

    func testPodspecParsingVGODataEncryptor() throws {
        let specJSON = """
        {
          "name": "VGODataEncryptor",
          "version": "1.2.2",
          "summary": "A data encryptor wrapper for Solar.",
          "homepage": "https://gerrit.zhenguanyu.com/admin/repos/ios-module-VGODataEncryptor",
          "license": {
            "type": "MIT",
            "file": "LICENSE"
          },
          "authors": {
            "J.Zhou": "zhoujian@fenbi.com"
          },
          "source": {
            "git": "ssh://gerrit.zhenguanyu.com:29418/ios-module-VGODataEncryptor",
            "tag": "1.2.2"
          },
          "platforms": {
            "ios": "9.0"
          },
          "ios": {
            "vendored_frameworks": "VGODataEncryptor/VGODataEncryptor.xcframework"
          },
          "libraries": "c++"
        }
        """
        var spec = try JSONDecoder().decode(Podspec.self, from: specJSON.data(using: .utf8)!)
        spec = spec.resolvePodspec(selectedSubspecs: nil)
        
        let (projects, dependencies) = CocoaPodsInteractor().generateProjectDescription(
            for: spec,
            descriptionBaseSettings: [:],
            descriptionConfigurations: [],
            targetSettings: [:],
            podsDirectoryPath: AbsolutePath("/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods")
        )

        XCTAssertNoDifference(spec.name, "VGODataEncryptor")
        XCTAssertNoDifference(spec.version, "1.2.2")
        XCTAssertNoDifference(spec.platforms?.ios, "9.0")
        XCTAssertNoDifference(spec.vendoredFrameworks, ["VGODataEncryptor/VGODataEncryptor.xcframework"])
        XCTAssertNoDifference(spec.libraries, ["c++"])
        XCTAssertNoDifference(projects, [:])
        XCTAssertNoDifference(
            dependencies,
            [
                "VGODataEncryptor": [
                    ProjectDescription.TargetDependency.xcframework(
                        path: Path("/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/VGODataEncryptor/VGODataEncryptor/VGODataEncryptor.xcframework"),
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

    func testPodspecParsingTensorFlowLiteSwift() throws {
        let specJSON = """
        {
          "name": "TensorFlowLiteSwift",
          "version": "2.7.0",
          "authors": "Google Inc.",
          "license": {
            "type": "Apache"
          },
          "homepage": "https://github.com/tensorflow/tensorflow",
          "source": {
            "git": "https://github.com/tensorflow/tensorflow.git",
            "tag": "v2.7.0"
          },
          "summary": "TensorFlow Lite for Swift",
          "description": "TensorFlow Lite is TensorFlow's lightweight solution for Swift developers. It\nenables low-latency inference of on-device machine learning models with a\nsmall binary size and fast performance supporting hardware acceleration.",
          "platforms": {
            "ios": "9.0"
          },
          "module_name": "TensorFlowLite",
          "static_framework": true,
          "default_subspecs": "Core",
          "subspecs": [
            {
              "name": "Core",
              "dependencies": {
                "TensorFlowLiteC": [
                  "2.7.0"
                ]
              },
              "source_files": "tensorflow/lite/swift/Sources/*.swift",
              "exclude_files": "tensorflow/lite/swift/Sources/{CoreML,Metal}Delegate.swift",
              "testspecs": [
                {
                  "name": "Tests",
                  "test_type": "unit",
                  "source_files": "tensorflow/lite/swift/Tests/*.swift",
                  "exclude_files": "tensorflow/lite/swift/Tests/MetalDelegateTests.swift",
                  "resources": [
                    "tensorflow/lite/testdata/add.bin",
                    "tensorflow/lite/testdata/add_quantized.bin"
                  ]
                }
              ]
            },
            {
              "name": "CoreML",
              "source_files": "tensorflow/lite/swift/Sources/CoreMLDelegate.swift",
              "dependencies": {
                "TensorFlowLiteC/CoreML": [
                  "2.7.0"
                ],
                "TensorFlowLiteSwift/Core": [
                  "2.7.0"
                ]
              }
            },
            {
              "name": "Metal",
              "source_files": "tensorflow/lite/swift/Sources/MetalDelegate.swift",
              "dependencies": {
                "TensorFlowLiteC/Metal": [
                  "2.7.0"
                ],
                "TensorFlowLiteSwift/Core": [
                  "2.7.0"
                ]
              },
              "testspecs": [
                {
                  "name": "Tests",
                  "test_type": "unit",
                  "source_files": "tensorflow/lite/swift/Tests/{Interpreter,MetalDelegate}Tests.swift",
                  "resources": [
                    "tensorflow/lite/testdata/add.bin",
                    "tensorflow/lite/testdata/add_quantized.bin",
                    "tensorflow/lite/testdata/multi_add.bin"
                  ]
                }
              ]
            }
          ]
        }
        """
        var spec = try JSONDecoder().decode(Podspec.self, from: specJSON.data(using: .utf8)!)
        spec = spec.resolvePodspec(selectedSubspecs: ["CoreML", "Metal"])

        let (projects, dependencies) = CocoaPodsInteractor().generateProjectDescription(
            for: spec,
            descriptionBaseSettings: [:],
            descriptionConfigurations: [],
            targetSettings: [:],
            podsDirectoryPath: AbsolutePath("/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods")
        )

        XCTAssertNoDifference(spec.name, "TensorFlowLiteSwift")
        XCTAssertNoDifference(projects.values.first!.targets.first!.dependencies, [
            .external(name: "TensorFlowLiteC", condition: nil)
        ])
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

        let (projects, dependencies) = CocoaPodsInteractor().generateProjectDescription(
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

        XCTAssertNoDifference(projects, [:])
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

        let (projects, dependencies) = CocoaPodsInteractor().generateProjectDescription(
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

        let (projects, dependencies) = CocoaPodsInteractor().generateProjectDescription(
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

    func testPodspecRequireArcList() throws {
        let specJSON = """
        {
          "name": "MMKVCore",
          "version": "1.3.1",
          "summary": "MMKVCore for MMKV. MMKV is a cross-platform key-value storage framework developed by WeChat.",
          "description": "Don't use this library directly. Use MMKV instead.\nMMKV is an efficient, complete, easy-to-use mobile key-value storage framework used in the WeChat application.\nIt can be a replacement for NSUserDefaults & SQLite.",
          "homepage": "https://github.com/Tencent/MMKV",
          "license": {
            "type": "BSD 3-Clause",
            "file": "LICENSE.TXT"
          },
          "authors": {
            "guoling": "guoling@tencent.com"
          },
          "platforms": {
            "ios": "11.0",
            "osx": "10.13",
            "tvos": "13.0",
            "watchos": "4.0"
          },
          "source": {
            "git": "https://github.com/Tencent/MMKV.git",
            "tag": "v1.3.1"
          },
          "source_files": [
            "Core",
            "Core/*.{h,cpp,hpp}",
            "Core/aes/*",
            "Core/aes/openssl/*",
            "Core/crc32/*.h"
          ],
          "public_header_files": [
            "Core/MMBuffer.h",
            "Core/MMKV.h",
            "Core/MMKVLog.h",
            "Core/MMKVPredef.h",
            "Core/PBUtility.h",
            "Core/ScopedLock.hpp",
            "Core/ThreadLock.h",
            "Core/aes/openssl/openssl_md5.h",
            "Core/aes/openssl/openssl_opensslconf.h"
          ],
          "compiler_flags": "-x objective-c++",
          "requires_arc": [
            "Core/MemoryFile.cpp",
            "Core/ThreadLock.cpp",
            "Core/InterProcessLock.cpp",
            "Core/MMKVLog.cpp",
            "Core/PBUtility.cpp",
            "Core/MemoryFile_OSX.cpp",
            "aes/openssl/openssl_cfb128.cpp",
            "aes/openssl/openssl_aes_core.cpp",
            "aes/openssl/openssl_md5_one.cpp",
            "aes/openssl/openssl_md5_dgst.cpp",
            "aes/AESCrypt.cpp"
          ],
          "frameworks": "CoreFoundation",
          "ios": {
            "frameworks": "UIKit"
          },
          "libraries": [
            "z",
            "c++"
          ],
          "pod_target_xcconfig": {
            "CLANG_CXX_LANGUAGE_STANDARD": "gnu++17",
            "CLANG_CXX_LIBRARY": "libc++",
            "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF": "NO"
          }
        }
        """

        var spec = try JSONDecoder().decode(Podspec.self, from: specJSON.data(using: .utf8)!)
        spec = spec.resolvePodspec(selectedSubspecs: nil)

        XCTAssertNoDifference(spec.requiresArc, .array([
            "Core/MemoryFile.cpp",
            "Core/ThreadLock.cpp",
            "Core/InterProcessLock.cpp",
            "Core/MMKVLog.cpp",
            "Core/PBUtility.cpp",
            "Core/MemoryFile_OSX.cpp",
            "aes/openssl/openssl_cfb128.cpp",
            "aes/openssl/openssl_aes_core.cpp",
            "aes/openssl/openssl_md5_one.cpp",
            "aes/openssl/openssl_md5_dgst.cpp",
            "aes/AESCrypt.cpp"
        ]))

        let (projects, dependencies) = CocoaPodsInteractor().generateProjectDescription(
            for: spec,
            descriptionBaseSettings: [:],
            descriptionConfigurations: [],
            targetSettings: [:],
            podsDirectoryPath: AbsolutePath("/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods")
        )

        let headers = projects.values.first!.targets[0].headers

        XCTAssertNoDifference(headers!.public!.globs.map(\.glob.pathString).sorted(), [
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/MMBuffer.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/MMKV.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/MMKVLog.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/MMKVPredef.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/PBUtility.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/ScopedLock.hpp",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/ThreadLock.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/aes/openssl/openssl_md5.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/aes/openssl/openssl_opensslconf.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/Target Support Files/MMKVCore/MMKVCore-umbrella.h"
        ])
        XCTAssertNoDifference(headers!.private!.globs.map(\.glob.pathString), [])
        XCTAssertNoDifference(headers!.project!.globs.map(\.glob.pathString).sorted(), [
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/CodedInputData.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/CodedInputDataCrypt.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/CodedOutputData.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/InterProcessLock.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/KeyValueHolder.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/MMKVMetaInfo.hpp",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/MMKV_IO.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/MMKV_OSX.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/MemoryFile.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/MiniPBCoder.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/PBEncodeItem.hpp",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/aes/AESCrypt.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/aes/openssl/openssl_aes.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/aes/openssl/openssl_aes_locl.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/aes/openssl/openssl_arm_arch.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/aes/openssl/openssl_md32_common.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/aes/openssl/openssl_md5_locl.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore/Core/crc32/Checksum.h"
        ])

        XCTAssertNoDifference(dependencies, [
            "MMKVCore": [
                .project(
                    target: "MMKVCore",
                    path: Path("/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/MMKVCore")
                )
            ]
        ])
    }

    func testPodspecVendoredLibrary() throws {
        let specJSON = """
        {
          "name": "OpenSSL-Private",
          "version": "1.0.0",
          "summary": "OpenSSL for iOS and OS X",
          "description": "OpenSSL is an SSL/TLS and Crypto toolkit. Deprecated in Mac OS and gone in iOS, this spec gives your project non-deprecated OpenSSL support. Supports OSX and iOS including Simulator (armv7,armv7s,arm64,i386,x86_64).",
          "homepage": "http://gerrit.zhenguanyu.com/#/admin/projects/ios-module-OpenSSL",
          "license": {
            "type": "OpenSSL (OpenSSL/SSLeay)",
            "text": "LICENSE"
          },
          "source": {
            "git": "ssh://gerrit.zhenguanyu.com:29418/ios-module-OpenSSL",
            "tag": "1.0.0"
          },
          "authors": {
            "Mark J. Cox": "mark@openssl.org",
            "Ralf S. Engelschall": "rse@openssl.org",
            "Dr. Stephen Henson": "steve@openssl.org",
            "Ben Laurie": "ben@openssl.org",
            "Lutz Jänicke": "jaenicke@openssl.org",
            "Nils Larsch": "nils@openssl.org",
            "Richard Levitte": "nils@openssl.org",
            "Bodo Möller": "bodo@openssl.org",
            "Ulf Möller": "ulf@openssl.org",
            "Andy Polyakov": "appro@openssl.org",
            "Geoff Thorpe": "geoff@openssl.org",
            "Holger Reif": "holger@openssl.org",
            "Paul C. Sutton": "geoff@openssl.org",
            "Eric A. Young": "eay@cryptsoft.com",
            "Tim Hudson": "tjh@cryptsoft.com",
            "Justin Plouffe": "plouffe.justin@gmail.com"
          },
          "platforms": {
            "ios": "6.0"
          },
          "source_files": "include/openssl/**/*.h",
          "public_header_files": "include/openssl/**/*.h",
          "header_dir": "openssl",
          "preserve_paths": [
            "lib/libcrypto.a",
            "lib/libssl.a"
          ],
          "vendored_libraries": [
            "lib/libcrypto.a",
            "lib/libssl.a"
          ],
          "requires_arc": false
        }

        """

        var spec = try JSONDecoder().decode(Podspec.self, from: specJSON.data(using: .utf8)!)
        spec = spec.resolvePodspec(selectedSubspecs: nil)

        let (projects, dependencies) = CocoaPodsInteractor().generateProjectDescription(
            for: spec,
            descriptionBaseSettings: [:],
            descriptionConfigurations: [],
            targetSettings: [:],
            podsDirectoryPath: AbsolutePath("/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods")
        )

        XCTAssertNoDifference(projects, [:])

        XCTAssertNoDifference(dependencies, [
            "OpenSSL-Private": [
                .library(
                    path: Path("/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/OpenSSL-Private/lib/libcrypto.a"),
                    publicHeaders: Path("/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/Headers/Public/OpenSSL-Private"),
                    swiftModuleMap: nil
                ),
                .library(
                    path: Path("/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/OpenSSL-Private/lib/libssl.a"),
                    publicHeaders: Path("/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/Headers/Public/OpenSSL-Private"),
                    swiftModuleMap: nil
                ),
                .headerSearchPath(
                    path: Path("/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/Headers/Public/OpenSSL-Private")
                ),
                .headerSearchPath(
                    path: Path("/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/Headers/Public")
                )
            ]
        ])
    }

    func testPodspecAFNetworking() throws {
        let specJSON = """
        {
          "name": "AFNetworking",
          "version": "4.0.1",
          "license": "MIT",
          "summary": "A delightful networking framework for Apple platforms.",
          "homepage": "https://github.com/AFNetworking/AFNetworking",
          "social_media_url": "https://twitter.com/AFNetworking",
          "authors": {
            "Mattt Thompson": "m@mattt.me"
          },
          "source": {
            "git": "https://github.com/AFNetworking/AFNetworking.git",
            "tag": "4.0.1"
          },
          "platforms": {
            "ios": "9.0",
            "osx": "10.10",
            "watchos": "2.0",
            "tvos": "9.0"
          },
          "ios": {
            "pod_target_xcconfig": {
              "PRODUCT_BUNDLE_IDENTIFIER": "com.alamofire.AFNetworking"
            }
          },
          "osx": {
            "pod_target_xcconfig": {
              "PRODUCT_BUNDLE_IDENTIFIER": "com.alamofire.AFNetworking"
            }
          },
          "watchos": {
            "pod_target_xcconfig": {
              "PRODUCT_BUNDLE_IDENTIFIER": "com.alamofire.AFNetworking-watchOS"
            }
          },
          "tvos": {
            "pod_target_xcconfig": {
              "PRODUCT_BUNDLE_IDENTIFIER": "com.alamofire.AFNetworking"
            }
          },
          "source_files": "AFNetworking/AFNetworking.h",
          "deprecated_in_favor_of": "Alamofire",
          "subspecs": [
            {
              "name": "Serialization",
              "source_files": "AFNetworking/AFURL{Request,Response}Serialization.{h,m}"
            },
            {
              "name": "Security",
              "source_files": "AFNetworking/AFSecurityPolicy.{h,m}"
            },
            {
              "name": "Reachability",
              "platforms": {
                "ios": "9.0",
                "osx": "10.10",
                "tvos": "9.0"
              },
              "source_files": "AFNetworking/AFNetworkReachabilityManager.{h,m}"
            },
            {
              "name": "NSURLSession",
              "dependencies": {
                "AFNetworking/Serialization": [

                ],
                "AFNetworking/Security": [

                ]
              },
              "ios": {
                "dependencies": {
                  "AFNetworking/Reachability": [

                  ]
                }
              },
              "osx": {
                "dependencies": {
                  "AFNetworking/Reachability": [

                  ]
                }
              },
              "tvos": {
                "dependencies": {
                  "AFNetworking/Reachability": [

                  ]
                }
              },
              "source_files": [
                "AFNetworking/AF{URL,HTTP}SessionManager.{h,m}",
                "AFNetworking/AFCompatibilityMacros.h"
              ]
            },
            {
              "name": "UIKit",
              "platforms": {
                "ios": "9.0",
                "tvos": "9.0"
              },
              "dependencies": {
                "AFNetworking/NSURLSession": [

                ]
              },
              "source_files": "UIKit+AFNetworking"
            }
          ]
        }
        """

        var spec = try JSONDecoder().decode(Podspec.self, from: specJSON.data(using: .utf8)!)
        spec = spec.resolvePodspec(selectedSubspecs: nil)

        let (projects, dependencies) = CocoaPodsInteractor().generateProjectDescription(
            for: spec,
            descriptionBaseSettings: [:],
            descriptionConfigurations: [],
            targetSettings: [:],
            podsDirectoryPath: AbsolutePath("/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods")
        )

        let headers = projects.values.first!.targets[0].headers

        XCTAssertNoDifference(headers!.public!.globs.map(\.glob.pathString).sorted(), [
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/AFNetworking/AFNetworking/AFCompatibilityMacros.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/AFNetworking/AFNetworking/AFHTTPSessionManager.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/AFNetworking/AFNetworking/AFNetworkReachabilityManager.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/AFNetworking/AFNetworking/AFNetworking.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/AFNetworking/AFNetworking/AFSecurityPolicy.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/AFNetworking/AFNetworking/AFURLRequestSerialization.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/AFNetworking/AFNetworking/AFURLResponseSerialization.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/AFNetworking/AFNetworking/AFURLSessionManager.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/AFNetworking/UIKit+AFNetworking/AFAutoPurgingImageCache.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/AFNetworking/UIKit+AFNetworking/AFImageDownloader.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/AFNetworking/UIKit+AFNetworking/AFNetworkActivityIndicatorManager.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/AFNetworking/UIKit+AFNetworking/UIActivityIndicatorView+AFNetworking.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/AFNetworking/UIKit+AFNetworking/UIButton+AFNetworking.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/AFNetworking/UIKit+AFNetworking/UIImageView+AFNetworking.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/AFNetworking/UIKit+AFNetworking/UIKit+AFNetworking.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/AFNetworking/UIKit+AFNetworking/UIProgressView+AFNetworking.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/AFNetworking/UIKit+AFNetworking/UIRefreshControl+AFNetworking.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/AFNetworking/UIKit+AFNetworking/WKWebView+AFNetworking.h",
            "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods/Target Support Files/AFNetworking/AFNetworking-umbrella.h"
        ])
        XCTAssertNoDifference(headers!.private!.globs.map(\.glob.pathString), [])
        XCTAssertNoDifference(headers!.project!.globs.map(\.glob.pathString).sorted(), [

        ])
    }

    func testPodspecRCT() throws {
        let specJSON = #"""
        {
          "name": "React-RCTVibration",
          "version": "0.68.3",
          "summary": "An API for controlling the vibration hardware of the device.",
          "homepage": "https://reactnative.dev/",
          "documentation_url": "https://reactnative.dev/docs/vibration",
          "license": {
            "type": "MIT",
            "file": "LICENSE"
          },
          "authors": "Facebook, Inc. and its affiliates",
          "platforms": {
            "ios": "11.0"
          },
          "compiler_flags": "-DFOLLY_NO_CONFIG -DFOLLY_MOBILE=1 -DFOLLY_USE_LIBCPP=1 -Wno-comma -Wno-shorten-64-to-32 -Wno-nullability-completeness",
          "source": {
            "git": "ssh://gerrit.zhenguanyu.com:29418/ios-module-VGORNBase",
            "tag": "v0.68.3"
          },
          "source_files": "Libraries/Vibration/*.{m,mm}",
          "preserve_paths": [
            "package.json",
            "LICENSE",
            "LICENSE-docs"
          ],
          "header_dir": "RCTVibration",
          "pod_target_xcconfig": {
            "USE_HEADERMAP": "YES",
            "CLANG_CXX_LANGUAGE_STANDARD": "c++14",
            "HEADER_SEARCH_PATHS": "\"$(PODS_ROOT)/RCT-Folly\" \"${PODS_ROOT}/Headers/Public/React-Codegen/react/renderer/components\" \"${PODS_CONFIGURATION_BUILD_DIR}/React-Codegen/React_Codegen.framework/Headers\""
          },
          "frameworks": "AudioToolbox",
          "dependencies": {
            "RCT-Folly": [
              "2021.06.28.00-v2"
            ],
            "FBReactNativeSpec": [
              "0.68.3"
            ],
            "ReactCommon/turbomodule/core": [
              "0.68.3"
            ],
            "React-jsi": [
              "0.68.3"
            ],
            "React-Core/RCTVibrationHeaders": [
              "0.68.3"
            ]
          }
        }
        """#

        var spec = try JSONDecoder().decode(Podspec.self, from: specJSON.data(using: .utf8)!)
        spec = spec.resolvePodspec(selectedSubspecs: nil)

        let (projects, dependencies) = CocoaPodsInteractor().generateProjectDescription(
            for: spec,
            descriptionBaseSettings: [:],
            descriptionConfigurations: [],
            targetSettings: [:],
            podsDirectoryPath: AbsolutePath("/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods")
        )

        XCTAssertNoDifference(spec.dependencies?.keys.sorted(), [
            "FBReactNativeSpec",
            "RCT-Folly",
            "React-Core/RCTVibrationHeaders",
            "React-jsi",
            "ReactCommon/turbomodule/core"
        ])

    }

    func testPodspecReactCommon() throws {
        let specJSON = #"""
        {
          "name": "ReactCommon",
          "module_name": "ReactCommon",
          "version": "0.68.3",
          "summary": "-",
          "homepage": "https://reactnative.dev/",
          "license": {
            "type": "MIT",
            "file": "LICENSE"
          },
          "authors": "Facebook, Inc. and its affiliates",
          "platforms": {
            "ios": "11.0"
          },
          "source": {
            "git": "ssh://gerrit.zhenguanyu.com:29418/ios-module-VGORNBase",
            "tag": "v0.68.3"
          },
          "header_dir": "ReactCommon",
          "compiler_flags": "-DFOLLY_NO_CONFIG -DFOLLY_MOBILE=1 -DFOLLY_USE_LIBCPP=1 -Wno-comma -Wno-shorten-64-to-32 -Wno-documentation",
          "pod_target_xcconfig": {
            "HEADER_SEARCH_PATHS": "\"$(PODS_ROOT)/boost\" \"$(PODS_ROOT)/RCT-Folly\" \"$(PODS_ROOT)/DoubleConversion\" \"$(PODS_ROOT)/Headers/Private/React-Core\"",
            "USE_HEADERMAP": "YES",
            "CLANG_CXX_LANGUAGE_STANDARD": "c++14"
          },
          "dependencies": {
            "React-logger": [
              "0.68.3"
            ]
          },
          "subspecs": [
            {
              "name": "react_debug_core",
              "source_files": "ReactCommon/react/debug/*.{cpp,h}"
            },
            {
              "name": "turbomodule",
              "dependencies": {
                "React-callinvoker": [
                  "0.68.3"
                ],
                "React-perflogger": [
                  "0.68.3"
                ],
                "React-Core": [
                  "0.68.3"
                ],
                "React-cxxreact": [
                  "0.68.3"
                ],
                "React-jsi": [
                  "0.68.3"
                ],
                "RCT-Folly": [
                  "2021.06.28.00-v2"
                ],
                "DoubleConversion": [

                ],
                "glog": [

                ]
              },
              "subspecs": [
                {
                  "name": "core",
                  "source_files": [
                    "ReactCommon/react/nativemodule/core/ReactCommon/**/*.{cpp,h}",
                    "ReactCommon/react/nativemodule/core/platform/ios/**/*.{mm,cpp,h}"
                  ]
                },
                {
                  "name": "samples",
                  "source_files": [
                    "ReactCommon/react/nativemodule/samples/ReactCommon/**/*.{cpp,h}",
                    "ReactCommon/react/nativemodule/samples/platform/ios/**/*.{mm,cpp,h}"
                  ],
                  "dependencies": {
                    "ReactCommon/turbomodule/core": [
                      "0.68.3"
                    ]
                  }
                }
              ]
            }
          ]
        }
        """#

        var spec = try JSONDecoder().decode(Podspec.self, from: specJSON.data(using: .utf8)!)
        spec = spec.resolvePodspec(selectedSubspecs: nil)

        let (projects, dependencies) = CocoaPodsInteractor().generateProjectDescription(
            for: spec,
            descriptionBaseSettings: [:],
            descriptionConfigurations: [],
            targetSettings: [:],
            podsDirectoryPath: AbsolutePath("/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods")
        )

        XCTAssertNoDifference(spec.resolveSubspecNames(selectedSubspecs: nil), ["react_debug_core", "turbomodule"])
        XCTAssertNoDifference(spec.sourceFiles, [
            "ReactCommon/react/debug/*.{cpp,h}",
            "ReactCommon/react/nativemodule/core/ReactCommon/**/*.{cpp,h}",
            "ReactCommon/react/nativemodule/core/platform/ios/**/*.{mm,cpp,h}",
            "ReactCommon/react/nativemodule/samples/ReactCommon/**/*.{cpp,h}",
            "ReactCommon/react/nativemodule/samples/platform/ios/**/*.{mm,cpp,h}"
        ])
    }
}
