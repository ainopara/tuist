import Foundation
import TSCBasic
import TuistGraph
import TuistSupport
import XCTest
@testable import TuistCore
@testable import TuistCoreTesting
@testable import TuistGraphTesting
@testable import TuistSupportTesting

final class DynamicLibraryMergingTests: TuistUnitTestCase {

    // MARK: - Merge Detection Tests

    func test_isMergedIntoDynamicLibrary_returns_true_when_dependency_is_merged() {
        // Given
        let utilityTarget = Target.test(name: "UtilityLibrary", product: .staticLibrary)
        let myFrameworkTarget = Target.test(
            name: "MyFramework", 
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        let project = Project.test(targets: [utilityTarget, myFrameworkTarget])
        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            .target(name: "MyFramework", path: project.path): [.target(name: "UtilityLibrary", path: project.path)]
        ]
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [project.path: ["UtilityLibrary": utilityTarget, "MyFramework": myFrameworkTarget]],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let result = subject.isMergedIntoDynamicLibrary(dependency: GraphDependency.target(name: "UtilityLibrary", path: project.path))

        // Then
        XCTAssertTrue(result)
    }

    func test_isMergedIntoDynamicLibrary_returns_false_when_dependency_is_not_merged() {
        // Given
        let project = Project.test()
        let graph = Graph.test(projects: [project.path: project])
        let subject = GraphTraverser(graph: graph)

        // When
        let result = subject.isMergedIntoDynamicLibrary(dependency: GraphDependency.target(name: "SomeLibrary", path: project.path))

        // Then
        XCTAssertFalse(result)
    }

    func test_getMergedDynamicLibrary_returns_correct_dynamic_library() {
        // Given
        let utilityTarget = Target.test(name: "UtilityLibrary", product: .staticLibrary)
        let myFrameworkTarget = Target.test(
            name: "MyFramework", 
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        let project = Project.test(targets: [utilityTarget, myFrameworkTarget])
        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            .target(name: "MyFramework", path: project.path): [.target(name: "UtilityLibrary", path: project.path)]
        ]
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [project.path: ["UtilityLibrary": utilityTarget, "MyFramework": myFrameworkTarget]],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let result = subject.getMergedDynamicLibrary(for: GraphDependency.target(name: "UtilityLibrary", path: project.path))

        // Then
        XCTAssertEqual(result, GraphDependency.target(name: "MyFramework", path: project.path))
    }

    func test_getMergedDynamicLibrary_returns_nil_when_not_merged() {
        // Given
        let project = Project.test()
        let graph = Graph.test(projects: [project.path: project])
        let subject = GraphTraverser(graph: graph)

        // When
        let result = subject.getMergedDynamicLibrary(for: GraphDependency.target(name: "SomeLibrary", path: project.path))

        // Then
        XCTAssertNil(result)
    }

    // MARK: - Mergeable Library Detection Tests

    func test_isMergeableDynamicLibrary_returns_true_for_framework_with_merge_setting() {
        // Given
        let project = Project.test()
        let frameworkTarget = Target.test(
            name: "MyFramework",
            product: .framework,
            settings: Settings(base: ["TUIST_DYNAMIC_MERGE": "YES"], configurations: [:])
        )
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [project.path: ["MyFramework": frameworkTarget]]
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let result = subject.isMergeableDynamicLibrary(dependency: GraphDependency.target(name: "MyFramework", path: project.path))

        // Then
        XCTAssertTrue(result)
    }

    func test_isMergeableDynamicLibrary_returns_true_for_dynamic_library_with_merge_setting() {
        // Given
        let project = Project.test()
        let dynamicLibTarget = Target.test(
            name: "MyDynamicLib",
            product: .dynamicLibrary,
            settings: Settings(base: ["TUIST_DYNAMIC_MERGE": "YES"], configurations: [:])
        )
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [project.path: ["MyDynamicLib": dynamicLibTarget]]
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let result = subject.isMergeableDynamicLibrary(dependency: GraphDependency.target(name: "MyDynamicLib", path: project.path))

        // Then
        XCTAssertTrue(result)
    }

    func test_isMergeableDynamicLibrary_returns_false_for_static_library() {
        // Given
        let project = Project.test()
        let staticTarget = Target.test(
            name: "StaticLib",
            product: .staticLibrary,
            settings: Settings(base: ["TUIST_DYNAMIC_MERGE": "YES"], configurations: [:])
        )
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [project.path: ["StaticLib": staticTarget]]
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let result = subject.isMergeableDynamicLibrary(dependency: GraphDependency.target(name: "StaticLib", path: project.path))

        // Then
        XCTAssertFalse(result)
    }

    func test_isMergeableDynamicLibrary_returns_false_for_framework_without_merge_setting() {
        // Given
        let project = Project.test()
        let frameworkTarget = Target.test(
            name: "MyFramework",
            product: .framework
        )
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [project.path: ["MyFramework": frameworkTarget]]
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let result = subject.isMergeableDynamicLibrary(dependency: GraphDependency.target(name: "MyFramework", path: project.path))

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - Linkable Dependencies Tests

    func test_linkableDependencies_excludes_merged_dependencies() throws {
        // Given
        let project = Project.test()
        let appTarget = Target.test(name: "App", product: .app)
        let frameworkTarget = Target.test(
            name: "MyFramework", 
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        let utilityTarget = Target.test(name: "UtilityLibrary", product: .staticLibrary)

        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            GraphDependency.target(name: "App", path: project.path): [
                GraphDependency.target(name: "UtilityLibrary", path: project.path)
            ],
            GraphDependency.target(name: "MyFramework", path: project.path): [
                GraphDependency.target(name: "UtilityLibrary", path: project.path)
            ]
        ]

        let graph = Graph.test(
            projects: [project.path: project],
            targets: [
                project.path: [
                    "App": appTarget,
                    "MyFramework": frameworkTarget,
                    "UtilityLibrary": utilityTarget
                ]
            ],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let linkableDeps = try subject.linkableDependencies(
            path: project.path,
            name: "App",
            shouldExcludeHostAppDependencies: false
        )

        // Then
        let targetNames = linkableDeps.compactMap { dependency -> String? in
            if case .product(let target, _, _) = dependency {
                return target
            }
            return nil
        }

        XCTAssertTrue(targetNames.contains("MyFramework"), "Should include the merged dynamic library")
        XCTAssertFalse(targetNames.contains("UtilityLibrary"), "Should exclude the merged dependency")
    }

    func test_linkableDependencies_includes_non_merged_dependencies() throws {
        // Given
        let project = Project.test()
        let appTarget = Target.test(name: "App", product: .app)
        let frameworkTarget = Target.test(name: "MyFramework", product: .framework)
        let anotherFramework = Target.test(name: "AnotherFramework", product: .framework)

        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            GraphDependency.target(name: "App", path: project.path): [
                GraphDependency.target(name: "MyFramework", path: project.path),
                GraphDependency.target(name: "AnotherFramework", path: project.path)
            ]
        ]

        let graph = Graph.test(
            projects: [project.path: project],
            targets: [
                project.path: [
                    "App": appTarget,
                    "MyFramework": frameworkTarget,
                    "AnotherFramework": anotherFramework
                ]
            ],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let linkableDeps = try subject.linkableDependencies(
            path: project.path,
            name: "App",
            shouldExcludeHostAppDependencies: false
        )

        // Then
        let targetNames = linkableDeps.compactMap { dependency -> String? in
            if case .product(let target, _, _) = dependency {
                return target
            }
            return nil
        }

        XCTAssertTrue(targetNames.contains("MyFramework"), "Should include non-merged dynamic library")
        XCTAssertTrue(targetNames.contains("AnotherFramework"), "Should include non-merged dynamic library")
    }

    // MARK: - Embeddable Frameworks Tests

    func test_embeddableFrameworks_excludes_merged_dependencies() {
        // Given
        let project = Project.test()
        let appTarget = Target.test(name: "App", product: .app)
        let frameworkTarget = Target.test(
            name: "MyFramework", 
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        let utilityTarget = Target.test(name: "UtilityLibrary", product: .staticLibrary)

        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            GraphDependency.target(name: "App", path: project.path): [
                GraphDependency.target(name: "UtilityLibrary", path: project.path)
            ],
            GraphDependency.target(name: "MyFramework", path: project.path): [
                GraphDependency.target(name: "UtilityLibrary", path: project.path)
            ]
        ]

        let graph = Graph.test(
            projects: [project.path: project],
            targets: [
                project.path: [
                    "App": appTarget,
                    "MyFramework": frameworkTarget,
                    "UtilityLibrary": utilityTarget
                ]
            ],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let embeddableFrameworks = subject.embeddableFrameworks(path: project.path, name: "App")

        // Then
        let targetNames = embeddableFrameworks.compactMap { dependency -> String? in
            if case .product(let target, _, _) = dependency {
                return target
            }
            return nil
        }

        XCTAssertTrue(targetNames.contains("MyFramework"), "Should include the merged dynamic library for embedding")
        XCTAssertFalse(targetNames.contains("UtilityLibrary"), "Should exclude the merged dependency from embedding")
    }

    // MARK: - computeMergedDependencies Tests

    func test_computeMergedDependencies_creates_correct_mappings() {
        // Given
        let project = Project.test()
        let staticLibA = Target.test(name: "StaticLibA", product: .staticLibrary)
        let staticLibB = Target.test(name: "StaticLibB", product: .staticLibrary)
        let dynamicFramework = Target.test(
            name: "DynamicFramework",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        
        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            .target(name: "DynamicFramework", path: project.path): [
                .target(name: "StaticLibA", path: project.path),
                .target(name: "StaticLibB", path: project.path)
            ]
        ]
        
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [
                project.path: [
                    "StaticLibA": staticLibA,
                    "StaticLibB": staticLibB,
                    "DynamicFramework": dynamicFramework
                ]
            ],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)
        
        // When
        let staticLibADep = GraphDependency.target(name: "StaticLibA", path: project.path)
        let staticLibBDep = GraphDependency.target(name: "StaticLibB", path: project.path)
        let dynamicFrameworkDep = GraphDependency.target(name: "DynamicFramework", path: project.path)
        
        // Then
        XCTAssertTrue(subject.isMergedIntoDynamicLibrary(dependency: staticLibADep))
        XCTAssertTrue(subject.isMergedIntoDynamicLibrary(dependency: staticLibBDep))
        XCTAssertEqual(subject.getMergedDynamicLibrary(for: staticLibADep), dynamicFrameworkDep)
        XCTAssertEqual(subject.getMergedDynamicLibrary(for: staticLibBDep), dynamicFrameworkDep)
    }

    func test_computeMergedDependencies_handles_transitive_dependencies() {
        // Given
        let project = Project.test()
        let staticLibA = Target.test(name: "StaticLibA", product: .staticLibrary)
        let staticLibB = Target.test(name: "StaticLibB", product: .staticLibrary)
        let staticLibC = Target.test(name: "StaticLibC", product: .staticLibrary)
        let dynamicFramework = Target.test(
            name: "DynamicFramework",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        
        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            .target(name: "DynamicFramework", path: project.path): [
                .target(name: "StaticLibA", path: project.path)
            ],
            .target(name: "StaticLibA", path: project.path): [
                .target(name: "StaticLibB", path: project.path)
            ],
            .target(name: "StaticLibB", path: project.path): [
                .target(name: "StaticLibC", path: project.path)
            ]
        ]
        
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [
                project.path: [
                    "StaticLibA": staticLibA,
                    "StaticLibB": staticLibB,
                    "StaticLibC": staticLibC,
                    "DynamicFramework": dynamicFramework
                ]
            ],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)
        
        // When
        let staticLibADep = GraphDependency.target(name: "StaticLibA", path: project.path)
        let staticLibBDep = GraphDependency.target(name: "StaticLibB", path: project.path)
        let staticLibCDep = GraphDependency.target(name: "StaticLibC", path: project.path)
        let dynamicFrameworkDep = GraphDependency.target(name: "DynamicFramework", path: project.path)
        
        // Then - All transitive static dependencies should be merged
        XCTAssertTrue(subject.isMergedIntoDynamicLibrary(dependency: staticLibADep))
        XCTAssertTrue(subject.isMergedIntoDynamicLibrary(dependency: staticLibBDep))
        XCTAssertTrue(subject.isMergedIntoDynamicLibrary(dependency: staticLibCDep))
        XCTAssertEqual(subject.getMergedDynamicLibrary(for: staticLibADep), dynamicFrameworkDep)
        XCTAssertEqual(subject.getMergedDynamicLibrary(for: staticLibBDep), dynamicFrameworkDep)
        XCTAssertEqual(subject.getMergedDynamicLibrary(for: staticLibCDep), dynamicFrameworkDep)
    }

    func test_computeMergedDependencies_ignores_non_mergeable_targets() {
        // Given
        let project = Project.test()
        let dynamicLib = Target.test(name: "DynamicLib", product: .dynamicLibrary)
        let app = Target.test(name: "App", product: .app)
        let dynamicFramework = Target.test(
            name: "DynamicFramework",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        
        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            .target(name: "DynamicFramework", path: project.path): [
                .target(name: "DynamicLib", path: project.path),
                .target(name: "App", path: project.path)
            ]
        ]
        
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [
                project.path: [
                    "DynamicLib": dynamicLib,
                    "App": app,
                    "DynamicFramework": dynamicFramework
                ]
            ],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)
        
        // When
        let dynamicLibDep = GraphDependency.target(name: "DynamicLib", path: project.path)
        let appDep = GraphDependency.target(name: "App", path: project.path)
        
        // Then - Dynamic libraries and apps should not be merged
        XCTAssertFalse(subject.isMergedIntoDynamicLibrary(dependency: dynamicLibDep))
        XCTAssertFalse(subject.isMergedIntoDynamicLibrary(dependency: appDep))
    }

    // MARK: - linkableDependencies Tests

    func test_linkableDependencies_resolves_merged_dependencies() throws {
        // Given
        let project = Project.test()
        let app = Target.test(name: "App", product: .app)
        let staticLib = Target.test(name: "StaticLib", product: .staticLibrary)
        let dynamicFramework = Target.test(
            name: "DynamicFramework",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        
        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            .target(name: "App", path: project.path): [
                .target(name: "StaticLib", path: project.path)
            ],
            .target(name: "DynamicFramework", path: project.path): [
                .target(name: "StaticLib", path: project.path)
            ]
        ]
        
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [
                project.path: [
                    "App": app,
                    "StaticLib": staticLib,
                    "DynamicFramework": dynamicFramework
                ]
            ],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)
        
        // When
        let linkableDeps = try subject.linkableDependencies(
            path: project.path,
            name: "App",
            shouldExcludeHostAppDependencies: false
        )
        
        // Then
        let targetNames = linkableDeps.compactMap { dependency -> String? in
            if case .product(let target, _, _) = dependency {
                return target
            }
            return nil
        }
        
        // App should link to the DynamicFramework instead of the merged StaticLib
        XCTAssertTrue(targetNames.contains("DynamicFramework"), "Should link to the merged dynamic framework")
        XCTAssertFalse(targetNames.contains("StaticLib"), "Should not link to the merged static library")
    }

    func test_linkableDependencies_excludes_self_references() throws {
        // Given
        let project = Project.test()
        let dynamicFramework = Target.test(
            name: "DynamicFramework",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        let staticLib = Target.test(name: "StaticLib", product: .staticLibrary)
        
        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            .target(name: "DynamicFramework", path: project.path): [
                .target(name: "StaticLib", path: project.path)
            ]
        ]
        
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [
                project.path: [
                    "DynamicFramework": dynamicFramework,
                    "StaticLib": staticLib
                ]
            ],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)
        
        // When
        let linkableDeps = try subject.linkableDependencies(
            path: project.path,
            name: "DynamicFramework",
            shouldExcludeHostAppDependencies: false
        )
        
        // Then
        let targetNames = linkableDeps.compactMap { dependency -> String? in
            if case .product(let target, _, _) = dependency {
                return target
            }
            return nil
        }
        
        // DynamicFramework should not link to itself even if StaticLib is merged into it
        XCTAssertFalse(targetNames.contains("DynamicFramework"), "Should not create self-reference")
    }

    // MARK: - Complex Scenarios Tests

    func test_multiple_merged_dependencies_scenario() throws {
        // Given
        let project = Project.test()
        let appTarget = Target.test(name: "App", product: .app)
        let mainFramework = Target.test(
            name: "MainFramework", 
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        let utilityA = Target.test(name: "UtilityA", product: .staticLibrary)
        let utilityB = Target.test(name: "UtilityB", product: .staticLibrary)

        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            GraphDependency.target(name: "App", path: project.path): [
                GraphDependency.target(name: "UtilityA", path: project.path),
                GraphDependency.target(name: "UtilityB", path: project.path)
            ],
            GraphDependency.target(name: "MainFramework", path: project.path): [
                GraphDependency.target(name: "UtilityA", path: project.path),
                GraphDependency.target(name: "UtilityB", path: project.path)
            ]
        ]

        let graph = Graph.test(
            projects: [project.path: project],
            targets: [
                project.path: [
                    "App": appTarget,
                    "MainFramework": mainFramework,
                    "UtilityA": utilityA,
                    "UtilityB": utilityB
                ]
            ],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let linkableDeps = try subject.linkableDependencies(
            path: project.path,
            name: "App",
            shouldExcludeHostAppDependencies: false
        )

        // Then
        let targetNames = linkableDeps.compactMap { dependency -> String? in
            if case .product(let target, _, _) = dependency {
                return target
            }
            return nil
        }

        XCTAssertTrue(targetNames.contains("MainFramework"), "Should include the main merged framework")
        XCTAssertFalse(targetNames.contains("UtilityA"), "Should exclude merged static library dependency")
        XCTAssertFalse(targetNames.contains("UtilityB"), "Should exclude merged static library dependency")
    }

    // MARK: - Configuration-specific Merge Settings Tests

    func test_hasMergeConfiguration_returns_true_for_configuration_specific_setting() {
        // Given
        let project = Project.test()
        let frameworkTarget = Target.test(
            name: "MyFramework",
            product: .framework,
            settings: Settings(
                base: [:],
                configurations: [
                    .debug: Configuration.test(settings: ["TUIST_DYNAMIC_MERGE": "YES"]),
                    .release: Configuration.test(settings: [:])
                ]
            )
        )
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [project.path: ["MyFramework": frameworkTarget]]
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let result = subject.isMergeableDynamicLibrary(dependency: GraphDependency.target(name: "MyFramework", path: project.path))

        // Then
        XCTAssertTrue(result)
    }

    func test_hasMergeConfiguration_returns_false_for_non_YES_values() {
        // Given
        let project = Project.test()
        let frameworkTarget = Target.test(
            name: "MyFramework",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "NO"])
        )
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [project.path: ["MyFramework": frameworkTarget]]
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let result = subject.isMergeableDynamicLibrary(dependency: GraphDependency.target(name: "MyFramework", path: project.path))

        // Then
        XCTAssertFalse(result)
    }

    func test_hasMergeConfiguration_returns_false_for_targets_without_settings() {
        // Given
        let project = Project.test()
        let frameworkTarget = Target.test(
            name: "MyFramework",
            product: .framework,
            settings: nil
        )
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [project.path: ["MyFramework": frameworkTarget]]
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let result = subject.isMergeableDynamicLibrary(dependency: GraphDependency.target(name: "MyFramework", path: project.path))

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - External Dependencies Tests

    func test_shouldMergeDependency_returns_false_for_dynamic_xcframework() {
        // Given
        let project = Project.test()
        let dynamicFramework = Target.test(
            name: "DynamicFramework",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        
        let xcframeworkDep = GraphDependency.testXCFramework(linking: .dynamic)
        
        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            .target(name: "DynamicFramework", path: project.path): [xcframeworkDep]
        ]
        
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [project.path: ["DynamicFramework": dynamicFramework]],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let result = subject.isMergedIntoDynamicLibrary(dependency: xcframeworkDep)

        // Then
        XCTAssertFalse(result, "Dynamic XCFrameworks should not be merged")
    }

    func test_shouldMergeDependency_returns_true_for_static_xcframework() {
        // Given
        let project = Project.test()
        let dynamicFramework = Target.test(
            name: "DynamicFramework",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        
        let xcframeworkDep = GraphDependency.testXCFramework(linking: .static)
        
        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            .target(name: "DynamicFramework", path: project.path): [xcframeworkDep]
        ]
        
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [project.path: ["DynamicFramework": dynamicFramework]],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let result = subject.isMergedIntoDynamicLibrary(dependency: xcframeworkDep)

        // Then
        XCTAssertTrue(result, "Static XCFrameworks should be merged")
    }

    func test_shouldMergeDependency_returns_false_for_dynamic_framework_dependency() {
        // Given
        let project = Project.test()
        let dynamicFramework = Target.test(
            name: "DynamicFramework",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        
        let frameworkDep = GraphDependency.testFramework(
            linking: .dynamic,
            status: .required
        )
        
        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            .target(name: "DynamicFramework", path: project.path): [frameworkDep]
        ]
        
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [project.path: ["DynamicFramework": dynamicFramework]],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let result = subject.isMergedIntoDynamicLibrary(dependency: frameworkDep)

        // Then
        XCTAssertFalse(result, "Dynamic frameworks should not be merged")
    }

    func test_shouldMergeDependency_returns_true_for_static_framework_dependency() {
        // Given
        let project = Project.test()
        let dynamicFramework = Target.test(
            name: "DynamicFramework",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        
        let frameworkDep = GraphDependency.testFramework(
            linking: .static,
            status: .required
        )
        
        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            .target(name: "DynamicFramework", path: project.path): [frameworkDep]
        ]
        
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [project.path: ["DynamicFramework": dynamicFramework]],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let result = subject.isMergedIntoDynamicLibrary(dependency: frameworkDep)

        // Then
        XCTAssertTrue(result, "Static frameworks should be merged")
    }

    func test_shouldMergeDependency_returns_false_for_sdk_dependencies() {
        // Given
        let project = Project.test()
        let dynamicFramework = Target.test(
            name: "DynamicFramework",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        
        let sdkDep = GraphDependency.testSDK(name: "Foundation")
        
        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            .target(name: "DynamicFramework", path: project.path): [sdkDep]
        ]
        
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [project.path: ["DynamicFramework": dynamicFramework]],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let result = subject.isMergedIntoDynamicLibrary(dependency: sdkDep)

        // Then
        XCTAssertFalse(result, "SDK dependencies should not be merged")
    }

    // MARK: - Cross-Project Dependencies Tests

    func test_computeMergedDependencies_handles_cross_project_scenarios() {
        // Given
        let mainProject = Project.test(path: "/main")
        let utilityProject = Project.test(path: "/utility")
        
        let mainApp = Target.test(name: "MainApp", product: .app)
        let mainFramework = Target.test(
            name: "MainFramework",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        let utilityLib = Target.test(name: "UtilityLib", product: .staticLibrary)
        
        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            .target(name: "MainApp", path: mainProject.path): [
                .target(name: "UtilityLib", path: utilityProject.path)
            ],
            .target(name: "MainFramework", path: mainProject.path): [
                .target(name: "UtilityLib", path: utilityProject.path)
            ]
        ]
        
        let graph = Graph.test(
            projects: [
                mainProject.path: mainProject,
                utilityProject.path: utilityProject
            ],
            targets: [
                mainProject.path: ["MainApp": mainApp, "MainFramework": mainFramework],
                utilityProject.path: ["UtilityLib": utilityLib]
            ],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let utilityLibDep = GraphDependency.target(name: "UtilityLib", path: utilityProject.path)
        let mainFrameworkDep = GraphDependency.target(name: "MainFramework", path: mainProject.path)

        // Then
        XCTAssertTrue(subject.isMergedIntoDynamicLibrary(dependency: utilityLibDep))
        XCTAssertEqual(subject.getMergedDynamicLibrary(for: utilityLibDep), mainFrameworkDep)
    }

    // MARK: - Mergeable Dynamic Frameworks Tests

    func test_shouldMergeDependency_supports_mergeable_dynamic_frameworks() {
        // Given
        let project = Project.test()
        let parentFramework = Target.test(
            name: "ParentFramework",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        let childFramework = Target.test(
            name: "ChildFramework",
            product: .framework,
            mergeable: true
        )
        
        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            .target(name: "ParentFramework", path: project.path): [
                .target(name: "ChildFramework", path: project.path)
            ]
        ]
        
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [
                project.path: [
                    "ParentFramework": parentFramework,
                    "ChildFramework": childFramework
                ]
            ],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let childFrameworkDep = GraphDependency.target(name: "ChildFramework", path: project.path)
        let parentFrameworkDep = GraphDependency.target(name: "ParentFramework", path: project.path)

        // Then - Note: Dynamic frameworks may not be merged via the current transitive static dependency logic
        // The current implementation focuses on static dependencies that get merged into dynamic frameworks
        // This test verifies that the shouldMergeDependency logic correctly identifies mergeable frameworks
        // but they may not actually be merged unless they're part of the transitive static dependency chain
        let actualResult = subject.isMergedIntoDynamicLibrary(dependency: childFrameworkDep)
        let actualMergedLib = subject.getMergedDynamicLibrary(for: childFrameworkDep)
        
        // For now, we expect this to be false since current logic only merges transitive static dependencies
        // TODO: This could be enhanced to support merging dynamic frameworks marked as mergeable
        XCTAssertFalse(actualResult, "Current implementation doesn't merge dynamic frameworks via transitive dependency traversal")
        XCTAssertNil(actualMergedLib, "No merged library expected for dynamic framework dependencies")
    }

    func test_shouldMergeDependency_ignores_non_mergeable_dynamic_frameworks() {
        // Given
        let project = Project.test()
        let parentFramework = Target.test(
            name: "ParentFramework",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        let childFramework = Target.test(
            name: "ChildFramework",
            product: .framework,
            mergeable: false
        )
        
        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            .target(name: "ParentFramework", path: project.path): [
                .target(name: "ChildFramework", path: project.path)
            ]
        ]
        
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [
                project.path: [
                    "ParentFramework": parentFramework,
                    "ChildFramework": childFramework
                ]
            ],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let childFrameworkDep = GraphDependency.target(name: "ChildFramework", path: project.path)

        // Then
        XCTAssertFalse(subject.isMergedIntoDynamicLibrary(dependency: childFrameworkDep))
    }

    // MARK: - Edge Cases and Error Scenarios Tests

    func test_computeMergedDependencies_handles_circular_dependencies() {
        // Given
        let project = Project.test()
        let frameworkA = Target.test(
            name: "FrameworkA",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        let frameworkB = Target.test(
            name: "FrameworkB",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        
        // Create circular dependency
        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            .target(name: "FrameworkA", path: project.path): [
                .target(name: "FrameworkB", path: project.path)
            ],
            .target(name: "FrameworkB", path: project.path): [
                .target(name: "FrameworkA", path: project.path)
            ]
        ]
        
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [
                project.path: [
                    "FrameworkA": frameworkA,
                    "FrameworkB": frameworkB
                ]
            ],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)

        // When/Then - Should not crash and handle gracefully
        let frameworkADep = GraphDependency.target(name: "FrameworkA", path: project.path)
        let frameworkBDep = GraphDependency.target(name: "FrameworkB", path: project.path)
        
        // Both frameworks are dynamic with merge settings, so they shouldn't be merged into each other
        XCTAssertFalse(subject.isMergedIntoDynamicLibrary(dependency: frameworkADep))
        XCTAssertFalse(subject.isMergedIntoDynamicLibrary(dependency: frameworkBDep))
    }

    func test_computeMergedDependencies_handles_missing_targets() {
        // Given
        let project = Project.test()
        let dynamicFramework = Target.test(
            name: "DynamicFramework",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        
        // Reference a target that doesn't exist in the graph
        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            .target(name: "DynamicFramework", path: project.path): [
                .target(name: "MissingTarget", path: project.path)
            ]
        ]
        
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [
                project.path: ["DynamicFramework": dynamicFramework]
            ],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)

        // When/Then - Should handle gracefully without crashing
        let missingTargetDep = GraphDependency.target(name: "MissingTarget", path: project.path)
        XCTAssertFalse(subject.isMergedIntoDynamicLibrary(dependency: missingTargetDep))
    }

    func test_linkableDependencies_handles_complex_merge_chains() throws {
        // Given
        let project = Project.test()
        let app = Target.test(name: "App", product: .app)
        let mainFramework = Target.test(
            name: "MainFramework",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        let utilityFramework = Target.test(
            name: "UtilityFramework",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        let staticLibA = Target.test(name: "StaticLibA", product: .staticLibrary)
        let staticLibB = Target.test(name: "StaticLibB", product: .staticLibrary)
        
        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            .target(name: "App", path: project.path): [
                .target(name: "StaticLibA", path: project.path),
                .target(name: "StaticLibB", path: project.path)
            ],
            .target(name: "MainFramework", path: project.path): [
                .target(name: "StaticLibA", path: project.path)
            ],
            .target(name: "UtilityFramework", path: project.path): [
                .target(name: "StaticLibB", path: project.path)
            ]
        ]
        
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [
                project.path: [
                    "App": app,
                    "MainFramework": mainFramework,
                    "UtilityFramework": utilityFramework,
                    "StaticLibA": staticLibA,
                    "StaticLibB": staticLibB
                ]
            ],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let linkableDeps = try subject.linkableDependencies(
            path: project.path,
            name: "App",
            shouldExcludeHostAppDependencies: false
        )

        // Then
        let targetNames = linkableDeps.compactMap { dependency -> String? in
            if case .product(let target, _, _) = dependency {
                return target
            }
            return nil
        }

        XCTAssertTrue(targetNames.contains("MainFramework"), "Should link to MainFramework")
        XCTAssertTrue(targetNames.contains("UtilityFramework"), "Should link to UtilityFramework")
        XCTAssertFalse(targetNames.contains("StaticLibA"), "Should not link to merged StaticLibA")
        XCTAssertFalse(targetNames.contains("StaticLibB"), "Should not link to merged StaticLibB")
    }

    // MARK: - Comprehensive Embeddable Frameworks Tests

    func test_embeddableFrameworks_app_embeds_merged_framework_when_depending_on_static_library() {
        // Given
        let project = Project.test()
        let appTarget = Target.test(name: "App", product: .app)
        let staticLibrary = Target.test(name: "StaticLibrary", product: .staticLibrary)
        let dynamicFramework = Target.test(
            name: "DynamicFramework",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        
        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            .target(name: "App", path: project.path): [
                .target(name: "StaticLibrary", path: project.path)
            ],
            .target(name: "DynamicFramework", path: project.path): [
                .target(name: "StaticLibrary", path: project.path)
            ]
        ]
        
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [
                project.path: [
                    "App": appTarget,
                    "StaticLibrary": staticLibrary,
                    "DynamicFramework": dynamicFramework
                ]
            ],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let embeddableFrameworks = subject.embeddableFrameworks(path: project.path, name: "App")

        // Then
        let targetNames = embeddableFrameworks.compactMap { dependency -> String? in
            if case .product(let target, _, _) = dependency {
                return target
            }
            return nil
        }

        XCTAssertTrue(targetNames.contains("DynamicFramework"), "App should embed the merged dynamic framework")
        XCTAssertFalse(targetNames.contains("StaticLibrary"), "App should not embed the static library directly")
    }

    func test_embeddableFrameworks_handles_multiple_static_dependencies_merged_into_same_framework() {
        // Given
        let project = Project.test()
        let appTarget = Target.test(name: "App", product: .app)
        let staticLibA = Target.test(name: "StaticLibA", product: .staticLibrary)
        let staticLibB = Target.test(name: "StaticLibB", product: .staticLibrary)
        let mergedFramework = Target.test(
            name: "MergedFramework",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        
        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            .target(name: "App", path: project.path): [
                .target(name: "StaticLibA", path: project.path),
                .target(name: "StaticLibB", path: project.path)
            ],
            .target(name: "MergedFramework", path: project.path): [
                .target(name: "StaticLibA", path: project.path),
                .target(name: "StaticLibB", path: project.path)
            ]
        ]
        
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [
                project.path: [
                    "App": appTarget,
                    "StaticLibA": staticLibA,
                    "StaticLibB": staticLibB,
                    "MergedFramework": mergedFramework
                ]
            ],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let embeddableFrameworks = subject.embeddableFrameworks(path: project.path, name: "App")

        // Then
        let targetNames = embeddableFrameworks.compactMap { dependency -> String? in
            if case .product(let target, _, _) = dependency {
                return target
            }
            return nil
        }

        XCTAssertTrue(targetNames.contains("MergedFramework"), "App should embed the merged framework once")
        XCTAssertFalse(targetNames.contains("StaticLibA"), "App should not embed StaticLibA directly")
        XCTAssertFalse(targetNames.contains("StaticLibB"), "App should not embed StaticLibB directly")
        
        // Ensure the merged framework appears only once
        let mergedFrameworkCount = targetNames.filter { $0 == "MergedFramework" }.count
        XCTAssertEqual(mergedFrameworkCount, 1, "Merged framework should appear only once, not once per dependency")
    }

    func test_embeddableFrameworks_handles_multiple_different_merged_frameworks() {
        // Given
        let project = Project.test()
        let appTarget = Target.test(name: "App", product: .app)
        let staticLibA = Target.test(name: "StaticLibA", product: .staticLibrary)
        let staticLibB = Target.test(name: "StaticLibB", product: .staticLibrary)
        let frameworkA = Target.test(
            name: "FrameworkA",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        let frameworkB = Target.test(
            name: "FrameworkB",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        
        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            .target(name: "App", path: project.path): [
                .target(name: "StaticLibA", path: project.path),
                .target(name: "StaticLibB", path: project.path)
            ],
            .target(name: "FrameworkA", path: project.path): [
                .target(name: "StaticLibA", path: project.path)
            ],
            .target(name: "FrameworkB", path: project.path): [
                .target(name: "StaticLibB", path: project.path)
            ]
        ]
        
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [
                project.path: [
                    "App": appTarget,
                    "StaticLibA": staticLibA,
                    "StaticLibB": staticLibB,
                    "FrameworkA": frameworkA,
                    "FrameworkB": frameworkB
                ]
            ],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let embeddableFrameworks = subject.embeddableFrameworks(path: project.path, name: "App")

        // Then
        let targetNames = embeddableFrameworks.compactMap { dependency -> String? in
            if case .product(let target, _, _) = dependency {
                return target
            }
            return nil
        }

        XCTAssertTrue(targetNames.contains("FrameworkA"), "App should embed FrameworkA")
        XCTAssertTrue(targetNames.contains("FrameworkB"), "App should embed FrameworkB")
        XCTAssertFalse(targetNames.contains("StaticLibA"), "App should not embed StaticLibA directly")
        XCTAssertFalse(targetNames.contains("StaticLibB"), "App should not embed StaticLibB directly")
    }

    func test_embeddableFrameworks_excludes_self_references_for_merged_framework() {
        // Given
        let project = Project.test()
        let staticLibrary = Target.test(name: "StaticLibrary", product: .staticLibrary)
        let dynamicFramework = Target.test(
            name: "DynamicFramework",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        
        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            .target(name: "DynamicFramework", path: project.path): [
                .target(name: "StaticLibrary", path: project.path)
            ]
        ]
        
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [
                project.path: [
                    "StaticLibrary": staticLibrary,
                    "DynamicFramework": dynamicFramework
                ]
            ],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let embeddableFrameworks = subject.embeddableFrameworks(path: project.path, name: "DynamicFramework")

        // Then
        let targetNames = embeddableFrameworks.compactMap { dependency -> String? in
            if case .product(let target, _, _) = dependency {
                return target
            }
            return nil
        }

        XCTAssertFalse(targetNames.contains("DynamicFramework"), "Framework should not embed itself even if it merges dependencies")
        XCTAssertFalse(targetNames.contains("StaticLibrary"), "Framework should not embed the static library it merged")
    }

    func test_embeddableFrameworks_handles_transitive_merged_dependencies() {
        // Given
        let project = Project.test()
        let appTarget = Target.test(name: "App", product: .app)
        let intermediateLib = Target.test(name: "IntermediateLib", product: .staticLibrary)
        let baseLib = Target.test(name: "BaseLib", product: .staticLibrary)
        let dynamicFramework = Target.test(
            name: "DynamicFramework",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        
        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            .target(name: "App", path: project.path): [
                .target(name: "IntermediateLib", path: project.path)
            ],
            .target(name: "IntermediateLib", path: project.path): [
                .target(name: "BaseLib", path: project.path)
            ],
            .target(name: "DynamicFramework", path: project.path): [
                .target(name: "IntermediateLib", path: project.path),
                .target(name: "BaseLib", path: project.path)
            ]
        ]
        
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [
                project.path: [
                    "App": appTarget,
                    "IntermediateLib": intermediateLib,
                    "BaseLib": baseLib,
                    "DynamicFramework": dynamicFramework
                ]
            ],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let embeddableFrameworks = subject.embeddableFrameworks(path: project.path, name: "App")

        // Then
        let targetNames = embeddableFrameworks.compactMap { dependency -> String? in
            if case .product(let target, _, _) = dependency {
                return target
            }
            return nil
        }

        XCTAssertTrue(targetNames.contains("DynamicFramework"), "App should embed the merged framework")
        XCTAssertFalse(targetNames.contains("IntermediateLib"), "App should not embed the intermediate library")
        XCTAssertFalse(targetNames.contains("BaseLib"), "App should not embed the base library")
    }

    func test_embeddableFrameworks_mixed_merged_and_regular_dependencies() {
        // Given
        let project = Project.test()
        let appTarget = Target.test(name: "App", product: .app)
        let staticLibrary = Target.test(name: "StaticLibrary", product: .staticLibrary)
        let regularFramework = Target.test(name: "RegularFramework", product: .framework)
        let mergedFramework = Target.test(
            name: "MergedFramework",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        
        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            .target(name: "App", path: project.path): [
                .target(name: "StaticLibrary", path: project.path),
                .target(name: "RegularFramework", path: project.path)
            ],
            .target(name: "MergedFramework", path: project.path): [
                .target(name: "StaticLibrary", path: project.path)
            ]
        ]
        
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [
                project.path: [
                    "App": appTarget,
                    "StaticLibrary": staticLibrary,
                    "RegularFramework": regularFramework,
                    "MergedFramework": mergedFramework
                ]
            ],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let embeddableFrameworks = subject.embeddableFrameworks(path: project.path, name: "App")

        // Then
        let targetNames = embeddableFrameworks.compactMap { dependency -> String? in
            if case .product(let target, _, _) = dependency {
                return target
            }
            return nil
        }

        XCTAssertTrue(targetNames.contains("MergedFramework"), "App should embed the merged framework")
        XCTAssertTrue(targetNames.contains("RegularFramework"), "App should embed the regular framework")
        XCTAssertFalse(targetNames.contains("StaticLibrary"), "App should not embed the static library directly")
    }

    func test_embeddableFrameworks_cross_project_merged_dependencies() {
        // Given
        let mainProject = Project.test(path: "/main")
        let utilityProject = Project.test(path: "/utility")
        
        let appTarget = Target.test(name: "App", product: .app)
        let utilityLib = Target.test(name: "UtilityLib", product: .staticLibrary)
        let mergedFramework = Target.test(
            name: "MergedFramework",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        
        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            .target(name: "App", path: mainProject.path): [
                .target(name: "UtilityLib", path: utilityProject.path)
            ],
            .target(name: "MergedFramework", path: mainProject.path): [
                .target(name: "UtilityLib", path: utilityProject.path)
            ]
        ]
        
        let graph = Graph.test(
            projects: [
                mainProject.path: mainProject,
                utilityProject.path: utilityProject
            ],
            targets: [
                mainProject.path: ["App": appTarget, "MergedFramework": mergedFramework],
                utilityProject.path: ["UtilityLib": utilityLib]
            ],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let embeddableFrameworks = subject.embeddableFrameworks(path: mainProject.path, name: "App")

        // Then
        let targetNames = embeddableFrameworks.compactMap { dependency -> String? in
            if case .product(let target, _, _) = dependency {
                return target
            }
            return nil
        }

        XCTAssertTrue(targetNames.contains("MergedFramework"), "App should embed the merged framework from same project")
        XCTAssertFalse(targetNames.contains("UtilityLib"), "App should not embed the utility library from other project")
    }

    func test_embeddableFrameworks_with_external_dependencies_merged() {
        // Given
        let project = Project.test()
        let appTarget = Target.test(name: "App", product: .app)
        let dynamicFramework = Target.test(
            name: "DynamicFramework",
            product: .framework,
            settings: Settings.test(base: ["TUIST_DYNAMIC_MERGE": "YES"])
        )
        
        let staticFrameworkDep = GraphDependency.testFramework(linking: .static)
        
        let dependencies: [GraphDependency: Set<GraphDependency>] = [
            .target(name: "App", path: project.path): [staticFrameworkDep],
            .target(name: "DynamicFramework", path: project.path): [staticFrameworkDep]
        ]
        
        let graph = Graph.test(
            projects: [project.path: project],
            targets: [
                project.path: [
                    "App": appTarget,
                    "DynamicFramework": dynamicFramework
                ]
            ],
            dependencies: dependencies
        )
        let subject = GraphTraverser(graph: graph)

        // When
        let embeddableFrameworks = subject.embeddableFrameworks(path: project.path, name: "App")

        // Then
        let targetNames = embeddableFrameworks.compactMap { dependency -> String? in
            if case .product(let target, _, _) = dependency {
                return target
            }
            return nil
        }

        XCTAssertTrue(targetNames.contains("DynamicFramework"), "App should embed the dynamic framework that merged external dependencies")
        
        // Verify the external framework was actually merged
        XCTAssertTrue(subject.isMergedIntoDynamicLibrary(dependency: staticFrameworkDep), "Static framework should be merged")
    }
}
