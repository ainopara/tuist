//
//  File.swift
//  
//
//  Created by Zheng Li on 2022/8/10.
//

import Foundation

@propertyWrapper
public struct ImplicitStringList {
    public let wrappedValue: [String]?

    public init(wrappedValue: [String]?) {
        self.wrappedValue = wrappedValue
    }
}

extension ImplicitStringList: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode([String].self) {
            self.wrappedValue = value
        } else if let value = try? container.decode(String.self) {
            self.wrappedValue = [value]
        } else {
            self.wrappedValue = nil
        }
    }
}

public extension KeyedDecodingContainer {
    func decode(
        _ type: ImplicitStringList.Type,
        forKey key: Key
    ) throws -> ImplicitStringList {
        try decodeIfPresent(type, forKey: key) ?? ImplicitStringList(wrappedValue: nil)
    }
}

public enum BoolOrImplicitStringList: Decodable {
    case bool(Bool)
    case implicitStringList(ImplicitStringList)
    case error

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(ImplicitStringList.self) {
            self = .implicitStringList(value)
        } else {
            self = .error
        }
    }
}
