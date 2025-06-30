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

    let pathToPodsRoot = "/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods"

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

        XCTAssertNoDifference(
            Podspec.expandToValidGlob(from: "MLKitDigitalInkRecognition_resource/**"),
            [
                "MLKitDigitalInkRecognition_resource/**"
            ]
        )


    }

    func testPodspecParsingMobileQuickLogin() throws {
        let specJSON = """
        {
          "name": "MobileQuickLogin",
          "version": "9.6.6",
          "summary": "Mobile Quick Login",
          "homepage": "https://wiki.zhenguanyu.com/iOS/Modules",
          "license": "Private",
          "authors": {
            "huangjx": "huangjx@fenbi.com"
          },
          "source": {
            "http": "https://app.zhenguanyu.com/iphone/xcframeworks/MobileQuickLogin/9.6.6/MobileQuickLogin.zip"
          },
          "platforms": {
            "ios": "8.0"
          },
          "vendored_frameworks": [
            "TYRZSDK.xcframework"
          ],
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
            podsDirectoryPath: AbsolutePath(pathToPodsRoot)
        )

        XCTAssertNoDifference(spec.name, "MobileQuickLogin")
        XCTAssertNoDifference(spec.version, "9.6.6")
        XCTAssertNoDifference(spec.platforms?.ios, "8.0")
        XCTAssertNoDifference(spec.vendoredFrameworks, ["TYRZSDK.xcframework"])
        XCTAssertNoDifference(spec.resources, nil)
        XCTAssertNoDifference(spec.podTargetXcconfig?["OTHER_LDFLAGS"]?.wrappedValue, ["-ObjC"])
        XCTAssertNoDifference(spec.weakFrameworks, ["Network"])
        XCTAssertNoDifference(projects, [:])
        XCTAssertNoDifference(
            dependencies,
            [
                "MobileQuickLogin": [
                    ProjectDescription.TargetDependency.xcframework(
                        path: Path("\(pathToPodsRoot)/MobileQuickLogin/TYRZSDK.xcframework"),
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
            podsDirectoryPath: AbsolutePath(pathToPodsRoot)
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
                        path: Path("\(pathToPodsRoot)/VGODataEncryptor/VGODataEncryptor/VGODataEncryptor.xcframework"),
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
            podsDirectoryPath: AbsolutePath(pathToPodsRoot)
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
            podsDirectoryPath: AbsolutePath(pathToPodsRoot)
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
                        path: Path("\(pathToPodsRoot)/TensorFlowLiteC/Frameworks/TensorFlowLiteC.framework"),
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
            podsDirectoryPath: AbsolutePath(pathToPodsRoot)
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
            podsDirectoryPath: AbsolutePath(pathToPodsRoot)
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
            podsDirectoryPath: AbsolutePath(pathToPodsRoot)
        )

        let headers = projects.values.first!.targets[0].headers

        XCTAssertNoDifference(headers!.public!.globs.map(\.glob.pathString).sorted(), [
            "\(pathToPodsRoot)/MMKVCore/Core/MMBuffer.h",
            "\(pathToPodsRoot)/MMKVCore/Core/MMKV.h",
            "\(pathToPodsRoot)/MMKVCore/Core/MMKVLog.h",
            "\(pathToPodsRoot)/MMKVCore/Core/MMKVPredef.h",
            "\(pathToPodsRoot)/MMKVCore/Core/PBUtility.h",
            "\(pathToPodsRoot)/MMKVCore/Core/ScopedLock.hpp",
            "\(pathToPodsRoot)/MMKVCore/Core/ThreadLock.h",
            "\(pathToPodsRoot)/MMKVCore/Core/aes/openssl/openssl_md5.h",
            "\(pathToPodsRoot)/MMKVCore/Core/aes/openssl/openssl_opensslconf.h",
            "\(pathToPodsRoot)/Target Support Files/MMKVCore/MMKVCore-umbrella.h"
        ])
        XCTAssertNoDifference(headers!.private!.globs.map(\.glob.pathString), [])
        XCTAssertNoDifference(headers!.project!.globs.map(\.glob.pathString).sorted(), [
            "\(pathToPodsRoot)/MMKVCore/Core/CodedInputData.h",
            "\(pathToPodsRoot)/MMKVCore/Core/CodedInputDataCrypt.h",
            "\(pathToPodsRoot)/MMKVCore/Core/CodedOutputData.h",
            "\(pathToPodsRoot)/MMKVCore/Core/InterProcessLock.h",
            "\(pathToPodsRoot)/MMKVCore/Core/KeyValueHolder.h",
            "\(pathToPodsRoot)/MMKVCore/Core/MMKVMetaInfo.hpp",
            "\(pathToPodsRoot)/MMKVCore/Core/MMKV_IO.h",
            "\(pathToPodsRoot)/MMKVCore/Core/MMKV_OSX.h",
            "\(pathToPodsRoot)/MMKVCore/Core/MemoryFile.h",
            "\(pathToPodsRoot)/MMKVCore/Core/MiniPBCoder.h",
            "\(pathToPodsRoot)/MMKVCore/Core/PBEncodeItem.hpp",
            "\(pathToPodsRoot)/MMKVCore/Core/aes/AESCrypt.h",
            "\(pathToPodsRoot)/MMKVCore/Core/aes/openssl/openssl_aes.h",
            "\(pathToPodsRoot)/MMKVCore/Core/aes/openssl/openssl_aes_locl.h",
            "\(pathToPodsRoot)/MMKVCore/Core/aes/openssl/openssl_arm_arch.h",
            "\(pathToPodsRoot)/MMKVCore/Core/aes/openssl/openssl_md32_common.h",
            "\(pathToPodsRoot)/MMKVCore/Core/aes/openssl/openssl_md5_locl.h",
            "\(pathToPodsRoot)/MMKVCore/Core/crc32/Checksum.h"
        ])

        XCTAssertNoDifference(dependencies, [
            "MMKVCore": [
                .project(
                    target: "MMKVCore",
                    path: Path("\(pathToPodsRoot)/MMKVCore")
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
            podsDirectoryPath: AbsolutePath(pathToPodsRoot)
        )

        XCTAssertNoDifference(projects, [:])

        XCTAssertNoDifference(dependencies, [
            "OpenSSL-Private": [
                .library(
                    path: Path("\(pathToPodsRoot)/OpenSSL-Private/lib/libcrypto.a"),
                    publicHeaders: Path("\(pathToPodsRoot)/Headers/Public/OpenSSL-Private"),
                    swiftModuleMap: nil
                ),
                .library(
                    path: Path("\(pathToPodsRoot)/OpenSSL-Private/lib/libssl.a"),
                    publicHeaders: Path("\(pathToPodsRoot)/Headers/Public/OpenSSL-Private"),
                    swiftModuleMap: nil
                ),
                .headerSearchPath(
                    path: Path("\(pathToPodsRoot)/Headers/Public/OpenSSL-Private")
                ),
                .headerSearchPath(
                    path: Path("\(pathToPodsRoot)/Headers/Public")
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
            podsDirectoryPath: AbsolutePath(pathToPodsRoot)
        )

        let headers = projects.values.first!.targets[0].headers

        XCTAssertNoDifference(headers!.public!.globs.map(\.glob.pathString).sorted(), [
            "\(pathToPodsRoot)/AFNetworking/AFNetworking/AFCompatibilityMacros.h",
            "\(pathToPodsRoot)/AFNetworking/AFNetworking/AFHTTPSessionManager.h",
            "\(pathToPodsRoot)/AFNetworking/AFNetworking/AFNetworkReachabilityManager.h",
            "\(pathToPodsRoot)/AFNetworking/AFNetworking/AFNetworking.h",
            "\(pathToPodsRoot)/AFNetworking/AFNetworking/AFSecurityPolicy.h",
            "\(pathToPodsRoot)/AFNetworking/AFNetworking/AFURLRequestSerialization.h",
            "\(pathToPodsRoot)/AFNetworking/AFNetworking/AFURLResponseSerialization.h",
            "\(pathToPodsRoot)/AFNetworking/AFNetworking/AFURLSessionManager.h",
            "\(pathToPodsRoot)/AFNetworking/UIKit+AFNetworking/AFAutoPurgingImageCache.h",
            "\(pathToPodsRoot)/AFNetworking/UIKit+AFNetworking/AFImageDownloader.h",
            "\(pathToPodsRoot)/AFNetworking/UIKit+AFNetworking/AFNetworkActivityIndicatorManager.h",
            "\(pathToPodsRoot)/AFNetworking/UIKit+AFNetworking/UIActivityIndicatorView+AFNetworking.h",
            "\(pathToPodsRoot)/AFNetworking/UIKit+AFNetworking/UIButton+AFNetworking.h",
            "\(pathToPodsRoot)/AFNetworking/UIKit+AFNetworking/UIImageView+AFNetworking.h",
            "\(pathToPodsRoot)/AFNetworking/UIKit+AFNetworking/UIKit+AFNetworking.h",
            "\(pathToPodsRoot)/AFNetworking/UIKit+AFNetworking/UIProgressView+AFNetworking.h",
            "\(pathToPodsRoot)/AFNetworking/UIKit+AFNetworking/UIRefreshControl+AFNetworking.h",
            "\(pathToPodsRoot)/AFNetworking/UIKit+AFNetworking/WKWebView+AFNetworking.h",
            "\(pathToPodsRoot)/Target Support Files/AFNetworking/AFNetworking-umbrella.h"
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
            podsDirectoryPath: AbsolutePath(pathToPodsRoot)
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
            podsDirectoryPath: AbsolutePath(pathToPodsRoot)
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

    func testPodspecYTKUtils() throws {
        let specJSON = #"""
        {
          "name": "YTKUtils",
          "version": "1.3.15.0",
          "summary": "Common utils.",
          "homepage": "https://wiki.zhenguanyu.com/iOS/Modules/YTKUtils",
          "license": "Private",
          "authors": {
            "lancy": "lancy@fenbi.com"
          },
          "source": {
            "git": "ssh://gerrit.zhenguanyu.com:29418/ios-module-YTKUtils",
            "tag": "1.3.15.0"
          },
          "source_files": "Classes/YTKUtils.h",
          "frameworks": [
            "UIKit",
            "CoreTelephony"
          ],
          "libraries": "c++",
          "platforms": {
            "ios": "9.0"
          },
          "dependencies": {
            "MBProgressHUD": [
              "~> 0.9.2"
            ],
            "AFNetworking/Reachability": [
              "~> 4.0"
            ]
          },
          "default_subspecs": [
            "NonARC",
            "Utils",
            "Macros",
            "NSString",
            "Collections",
            "NSData",
            "UIDevice",
            "UIView",
            "UIButton",
            "UITableViewCell",
            "NSDate",
            "UIGestureRecognizer",
            "NSNull",
            "NSNumber",
            "NSObject"
          ],
          "subspecs": [
            {
              "name": "NonARC",
              "source_files": "Classes/NonARC/**/*.{h,m,mm}",
              "requires_arc": false,
              "compiler_flags": "-fno-objc-arc"
            },
            {
              "name": "Utils",
              "source_files": "Classes/Utils/**/*.{h,m,mm}",
              "requires_arc": true,
              "dependencies": {
                "YTKUtils/Macros": [

                ],
                "YTKUtils/NSString": [

                ],
                "YTKUtils/Collections": [

                ],
                "YTKUtils/NSData": [

                ]
              }
            },
            {
              "name": "Macros",
              "source_files": "Classes/Macros/**/*.{h,m,mm}",
              "requires_arc": true
            },
            {
              "name": "NSString",
              "source_files": "Classes/NSString/**/*.{h,m,mm}",
              "requires_arc": true,
              "dependencies": {
                "YTKUtils/Macros": [

                ]
              }
            },
            {
              "name": "Collections",
              "source_files": "Classes/Collections/**/*.{h,m,mm}",
              "requires_arc": true,
              "dependencies": {
                "YTKUtils/Macros": [

                ]
              }
            },
            {
              "name": "NSData",
              "source_files": "Classes/NSData/**/*.{h,m,mm}",
              "requires_arc": true,
              "dependencies": {
                "YTKUtils/NonARC": [

                ]
              }
            },
            {
              "name": "UIDevice",
              "source_files": "Classes/UIDevice/**/*.{h,m,mm}",
              "requires_arc": true,
              "dependencies": {
                "YTKUtils/NSString": [

                ]
              }
            },
            {
              "name": "UIView",
              "source_files": "Classes/UIView/**/*.{h,m,mm}",
              "requires_arc": true
            },
            {
              "name": "NSDate",
              "source_files": "Classes/NSDate/**/*.{h,m,mm}",
              "requires_arc": true
            },
            {
              "name": "UIButton",
              "source_files": "Classes/UIButton/**/*.{h,m,mm}",
              "requires_arc": true
            },
            {
              "name": "UITableViewCell",
              "source_files": "Classes/UITableViewCell/**/*.{h,m,mm}",
              "requires_arc": true
            },
            {
              "name": "UIGestureRecognizer",
              "source_files": "Classes/UIGestureRecognizer/**/*.{h,m,mm}",
              "requires_arc": true
            },
            {
              "name": "NSNull",
              "source_files": "Classes/NSNull/**/*.{h,m,mm}",
              "requires_arc": true
            },
            {
              "name": "NSNumber",
              "source_files": "Classes/NSNumber/**/*.{h,m,mm}",
              "requires_arc": true
            },
            {
              "name": "NSObject",
              "source_files": "Classes/NSObject/**/*.{h,m,mm}",
              "requires_arc": true
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
            podsDirectoryPath: AbsolutePath(pathToPodsRoot)
        )

        XCTAssertNoDifference(spec.resolveSubspecNames(selectedSubspecs: nil), [
            "Collections",
            "Macros",
            "NSData",
            "NSDate",
            "NSNull",
            "NSNumber",
            "NSObject",
            "NSString",
            "NonARC",
            "UIButton",
            "UIDevice",
            "UIGestureRecognizer",
            "UITableViewCell",
            "UIView",
            "Utils"
        ])

        let commonCompilerFlags = "-w -Xanalyzer -analyzer-disable-all-checks"
        let sourceInfos = projects.first!.value.targets.first!.sourceTestDescriptions
            .map {
                return (
                    $0.key.replacingOccurrences(of: pathToPodsRoot, with: ""),
                    $0.value.replacingOccurrences(of: commonCompilerFlags, with: "")
                )
            }
            .reduce(into: [:]) { $0[$1.0] = $1.1 }

        XCTAssertNoDifference(sourceInfos, [
              "/YTKUtils/Classes/Collections/NSArray+Join.m": "",
              "/YTKUtils/Classes/Collections/NSArray+jsonString.m": "",
              "/YTKUtils/Classes/Collections/NSDictionary+jsonString.m": "",
              "/YTKUtils/Classes/Collections/NSSet+join.m": "",
              "/YTKUtils/Classes/NSData/NSData+AESAdditions.m": "",
              "/YTKUtils/Classes/NSDate/NSDate+LongToDate.m": "",
              "/YTKUtils/Classes/NSDate/NSDate+Utilities.m": "",
              "/YTKUtils/Classes/NSNull/NSNull+stringValue.m": "",
              "/YTKUtils/Classes/NSNumber/NSNumber+dateValue.m": "",
              "/YTKUtils/Classes/NSObject/NSObject+Notification.m": "",
              "/YTKUtils/Classes/NSString/NSString+MD5Addition.m": "",
              "/YTKUtils/Classes/NSString/NSString+objectFromJSONString.m": "",
              "/YTKUtils/Classes/NSString/NSString+stringValue.m": "",
              "/YTKUtils/Classes/NonARC/Base64_Encoding/NSData+Base64.m": "-fno-objc-arc -fno-objc-arc ",
              "/YTKUtils/Classes/NonARC/SecurityUtils/CryptoUtil.m": "-fno-objc-arc -fno-objc-arc ",
              "/YTKUtils/Classes/NonARC/SecurityUtils/KeychainUtil.m": "-fno-objc-arc -fno-objc-arc ",
              "/YTKUtils/Classes/UIButton/UIButton+addTouchTarget.m": "",
              "/YTKUtils/Classes/UIDevice/UIDevice+CYHardware.m": "",
              "/YTKUtils/Classes/UIDevice/UIDevice+IdentifierAddition.m": "",
              "/YTKUtils/Classes/UIDevice/UIDevice+JailBreak.m": "",
              "/YTKUtils/Classes/UIGestureRecognizer/UIGestureRecognizer+Cancel.m": "",
              "/YTKUtils/Classes/UITableViewCell/UITableViewCell+tableView.m": "",
              "/YTKUtils/Classes/UIView/UIView+frameAdjust.m": "",
              "/YTKUtils/Classes/UIView/UIView+viewWithType.m": "",
              "/YTKUtils/Classes/Utils/ApplicationUtils.m": "",
              "/YTKUtils/Classes/Utils/DateUtils.m": "",
              "/YTKUtils/Classes/Utils/EncryptUtils.mm": "",
              "/YTKUtils/Classes/Utils/FileUtils.m": "",
              "/YTKUtils/Classes/Utils/ImageUtils.m": "",
              "/YTKUtils/Classes/Utils/NSStringWrapper.m": "",
              "/YTKUtils/Classes/Utils/NetworkUtils.m": "",
              "/YTKUtils/Classes/Utils/PinyinUtils.m": "",
              "/YTKUtils/Classes/Utils/RegexUtils.m": "",
              "/YTKUtils/Classes/Utils/YTKAES256EncryptUtils.m": "",
              "/YTKUtils/Classes/Utils/YTKAlertUtils.m": "",
              "/YTKUtils/Classes/Utils/YTKCookieUtils.m": "",
              "/YTKUtils/Classes/Utils/YTKSharedDataUtils.m": ""
        ])
    }
}

extension ProjectDescription.Target {
    var sourceTestDescriptions: [String: String] {
        var descriptions: [String: String] = [:]
        for source in sources?.globs ?? [] {
            descriptions[source.glob.pathString] = source.compilerFlags ?? "nil"
        }
        return descriptions
    }
}
