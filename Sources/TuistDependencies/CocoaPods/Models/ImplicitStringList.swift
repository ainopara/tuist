//
//  File.swift
//  
//
//  Created by Zheng Li on 2022/8/10.
//

import Foundation

@propertyWrapper
public struct ImplicitStringList {
    public var wrappedValue: [String]?

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



public enum BoolOrImplicitStringList: Decodable, Equatable {
    case bool(Bool)
    case array([String])

    struct DecodingError: Error {
        let message: String
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(ImplicitStringList.self).wrappedValue {
            self = .array(value)
        } else {
            throw DecodingError(message: "Unknown Value for BoolOrImplicitStringList")
        }
    }
}
