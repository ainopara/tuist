//
//  CocoaPodDependencyType.swift
//  ProjectDescriptionHelpers
//
//  Created by zhangpeibj01 on 2022/8/3.
//

import Foundation

public protocol CommonCocoaPod {
    var podName: String { get }
    var subspecName: String? { get }
}

public enum PodDependencyType {
    case directPodspec(PodDirectPodspec)
    case specifyVersion(PodSpecifyVersion)
    case gitCommit(PodGitCommit)
    case gitTag(PodGitTag)
    case gitBranch(PodGitBranch)
    case gitNotSpecify(PodGitNotSpecify)

    public var commonCocoaPod: CommonCocoaPod {
        switch self {
        case .directPodspec(let podDirectPodspec):
            return podDirectPodspec
        case .specifyVersion(let podSpecifyVersion):
            return podSpecifyVersion
        case .gitCommit(let podGitCommit):
            return podGitCommit
        case .gitTag(let podGitTag):
            return podGitTag
        case .gitBranch(let podGitBranch):
            return podGitBranch
        case .gitNotSpecify(let podGitNotSpecify):
            return podGitNotSpecify
        }
    }

    public var name: String {
        switch self {
        case .directPodspec(let podDirectPodspec):
            return podDirectPodspec.podName
        case .specifyVersion(let podSpecifyVersion):
            return podSpecifyVersion.podName
        case .gitCommit(let podGitCommit):
            return podGitCommit.podName
        case .gitTag(let podGitTag):
            return podGitTag.podName
        case .gitBranch(let podGitBranch):
            return podGitBranch.podName
        case .gitNotSpecify(let podGitNotSpecify):
            return podGitNotSpecify.podName
        }
    }

    public var subspecName: String? {
        switch self {
        case .directPodspec(let podDirectPodspec):
            return podDirectPodspec.subspecName
        case .specifyVersion(let podSpecifyVersion):
            return podSpecifyVersion.subspecName
        case .gitCommit(let podGitCommit):
            return podGitCommit.subspecName
        case .gitTag(let podGitTag):
            return podGitTag.subspecName
        case .gitBranch(let podGitBranch):
            return podGitBranch.subspecName
        case .gitNotSpecify(let podGitNotSpecify):
            return podGitNotSpecify.subspecName
        }
    }
}

public struct PodDirectPodspec: CommonCocoaPod {
    public let podName: String
    public let podspecPath: String
    public let subspecName: String?

    public init(
        podName: String,
        podspecPath: String,
        subspecName: String? = nil
    ) {
        self.podName = podName
        self.podspecPath = podspecPath
        self.subspecName = subspecName
    }
}

public struct PodSpecifyVersion: CommonCocoaPod {
    public let podName: String
    public let version: String
    public let subspecName: String?

    public init(
        podName: String,
        version: String,
        subspecName: String? = nil
    ) {
        self.podName = podName
        self.version = version
        self.subspecName = subspecName
    }
}

public struct PodGitCommit: CommonCocoaPod {
    public let podName: String
    public let gitURL: String
    public let commit: String
    public let subspecName: String?

    public init(
        podName: String,
        gitURL: String,
        commit: String,
        subspecName: String? = nil
    ) {
        self.podName = podName
        self.gitURL = gitURL
        self.commit = commit
        self.subspecName = subspecName
    }
}

public struct PodGitTag: CommonCocoaPod {
    public let podName: String
    public let gitURL: String
    public let tag: String
    public let subspecName: String?

    public init(
        podName: String,
        gitURL: String,
        tag: String,
        subspecName: String? = nil
    ) {
        self.podName = podName
        self.gitURL = gitURL
        self.tag = tag
        self.subspecName = subspecName
    }
}

public struct PodGitBranch: CommonCocoaPod {
    public let podName: String
    public let gitURL: String
    public let branch: String
    public let subspecName: String?

    public init(
        podName: String,
        gitURL: String,
        branch: String,
        subspecName: String? = nil
    ) {
        self.podName = podName
        self.gitURL = gitURL
        self.branch = branch
        self.subspecName = subspecName
    }
}

public struct PodGitNotSpecify: CommonCocoaPod {
    public let podName: String
    public let gitURL: String
    public let subspecName: String?

    public init(
        podName: String,
        gitURL: String,
        subspecName: String? = nil
    ) {
        self.podName = podName
        self.gitURL = gitURL
        self.subspecName = subspecName
    }
}
