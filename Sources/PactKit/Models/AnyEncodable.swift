//
//  AnyEncodable.swift
//  
//
//  Created by Arsenii Kovalenko on 16.08.2023.
//

import Foundation

public struct AnyEncodable: Encodable {

    private let _encode: (Encoder) throws -> Void

    public init<T: Encodable>(_ value: T) {
        self._encode = { encoder in
            var container = encoder.singleValueContainer()
            try container.encode(value)
        }
    }

    // Passing a `nil` as a generic type is not allowed so we are piggy-backing off of String type.
    public init(_ value: String?) {
        self._encode = { encoder in
            var container = encoder.singleValueContainer()
            (value != nil) ? try container.encode(value) : try container.encodeNil()
        }
    }

    public func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }

}
