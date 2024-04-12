//
//  XcodeConfigHelpers.swift
//  ProjectDescriptionHelpers
//
//  Created by Zheng Li on 2021/10/29.
//

import ProjectDescription

// MARK: - SettingsValue merge policy

private func replacePolicy(lhs: SettingValue, rhs: SettingValue) -> SettingValue {
    return rhs
}

private func mergePolicy(lhs: SettingValue, rhs: SettingValue) -> SettingValue {
    switch (lhs, rhs) {
    case (.string(let stringValue1), .string(let stringValue2)):
        return .array([stringValue1, stringValue2])
    case (.string(let stringValue1), .array(let arrayValue2)):
        return .array([stringValue1] + arrayValue2)
    case (.array(let arrayValue1), .string(let stringValue2)):
        return .array(arrayValue1 + [stringValue2])
    case (.array(let arrayValue1), .array(let arrayValue2)):
        return .array(arrayValue1 + arrayValue2)
    case (_, _):
        return lhs
    }
}

private func mergeToStringPolicy(lhs: SettingValue, rhs: SettingValue) -> SettingValue {
    switch (lhs, rhs) {
    case (.string(let stringValue1), .string(let stringValue2)):
        return .string([stringValue1, stringValue2].joined(separator: " "))
    case (.string(let stringValue1), .array(let arrayValue2)):
        return .string(([stringValue1] + arrayValue2).joined(separator: " "))
    case (.array(let arrayValue1), .string(let stringValue2)):
        return .string((arrayValue1 + [stringValue2]).joined(separator: " "))
    case (.array(let arrayValue1), .array(let arrayValue2)):
        return .string((arrayValue1 + arrayValue2).joined(separator: " "))
    case (_, _):
        return lhs
    }
}

func merging(policy: (SettingValue, SettingValue) -> SettingValue = replacePolicy, _ settings: SettingsDictionary...) -> SettingsDictionary {
    return settings.reduce([:], {
        return $0.merging($1, uniquingKeysWith: policy)
    })
}

public enum SettingsOperation {

    public struct MergePolicy {
        let policy: (SettingValue, SettingValue) -> SettingValue

        public static let replace: MergePolicy = .init(policy: replacePolicy)
        public static let merge: MergePolicy = .init(policy: mergePolicy)
    }

    case add(policy: MergePolicy, settings: SettingsDictionary)
    case delete(keys: Set<String>)
}

public struct SettingsModification {
    public var configNames: Set<String>
    public var operation: SettingsOperation

    private init(
        configNames: Set<String>,
        operation: SettingsOperation
    ) {
        self.configNames = configNames
        self.operation = operation
    }

    public static func add(
        configNames: Set<String>,
        policy: SettingsOperation.MergePolicy,
        settings: SettingsDictionary
    ) -> SettingsModification {
        return .init(configNames: configNames, operation: .add(policy: policy, settings: settings))
    }

    public static func add(
        configNames: Set<String>,
        policy: SettingsOperation.MergePolicy,
        key: String,
        value: ProjectDescription.SettingValue
    ) -> SettingsModification {
        return .init(configNames: configNames, operation: .add(policy: policy, settings: [
            key: value
        ]))
    }

    public static func merge(
        configNames: Set<String>,
        settings: SettingsDictionary
    ) -> SettingsModification {
        return .init(configNames: configNames, operation: .add(policy: .merge, settings: settings))
    }

    public static func replace(
        configNames: Set<String>,
        settings: SettingsDictionary
    ) -> SettingsModification {
        return .init(configNames: configNames, operation: .add(policy: .replace, settings: settings))
    }

    public static func delete(
        configNames: Set<String>,
        keys: Set<String>
    ) -> SettingsModification {
        return .init(configNames: configNames, operation: .delete(keys: keys))
    }

    public static func delete(
        configNames: Set<String>,
        key: String
    ) -> SettingsModification {
        return .init(configNames: configNames, operation: .delete(keys: [key]))
    }
}

public extension SettingsDictionary {

    func applying(operation: SettingsOperation, if condition: Bool) -> SettingsDictionary {
        if condition {
            return self.applying(operation: operation)
        } else {
            return self
        }
    }

    func applying(operations: [SettingsOperation], if condition: Bool) -> SettingsDictionary {
        if condition {
            return self.applying(operations: operations)
        } else {
            return self
        }
    }

    func applying(operation: SettingsOperation) -> SettingsDictionary {
        switch operation {
        case .add(let policy, let settings):
            return TuistDependencies.merging(policy: policy.policy, self, settings)
        case .delete(let keys):
            return self.removing(keys)
        }
    }

    func applying(operations: [SettingsOperation]) -> SettingsDictionary {
        return operations.reduce(self) { partialResult, operation in
            return partialResult.applying(operation: operation)
       }
    }

    func replacing(key: String, value: ProjectDescription.SettingValue) -> SettingsDictionary {
        replacing(settings: [key: value])
    }

    func replacing(settings: [String: ProjectDescription.SettingValue]) -> SettingsDictionary {
        TuistDependencies.merging(policy: replacePolicy, self, settings)
    }

    func merging(key: String, value: ProjectDescription.SettingValue) -> SettingsDictionary {
        merging(settings: [key: value])
    }

    func merging(settings: [String: ProjectDescription.SettingValue]) -> SettingsDictionary {
        TuistDependencies.merging(policy: mergePolicy, self, settings)
    }

    func deleting(keys: String...) -> SettingsDictionary {
        removing(Set(keys))
    }
}

extension SettingsDictionary {

    func removing(_ settingKeys: Set<String>) -> SettingsDictionary {
        return self.filter { (key, value) in return !settingKeys.contains(key) }
    }

    func convertedToStringValue() -> SettingsDictionary {
        return self.mapValues { value in
            switch value {
            case .array(let array):
                return .string(array.joined(separator: " "))
            case .string:
                return value
            }
        }
    }
}
