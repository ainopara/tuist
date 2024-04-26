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
        
        let (project, dependencies) = CocoaPodsInteractor().generateProjectDescription(
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
        XCTAssertNoDifference(project, [:])
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

        let (project, dependencies) = CocoaPodsInteractor().generateProjectDescription(
            for: spec,
            descriptionBaseSettings: [:],
            descriptionConfigurations: [],
            targetSettings: [:],
            podsDirectoryPath: AbsolutePath("/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods")
        )

        let headers = project.values.first!.targets[0].headers

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

        let (project, dependencies) = CocoaPodsInteractor().generateProjectDescription(
            for: spec,
            descriptionBaseSettings: [:],
            descriptionConfigurations: [],
            targetSettings: [:],
            podsDirectoryPath: AbsolutePath("/Users/ainopara/Documents/Projects/fenbi/leo-ios/Tuist/Dependencies/CocoaPods/Pods")
        )

        XCTAssertNoDifference(project, [:])

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
                )
            ]
        ])
    }
}
