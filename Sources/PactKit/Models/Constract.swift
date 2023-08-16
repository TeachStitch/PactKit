//
//  Contract.swift
//  
//
//  Created by Arsenii Kovalenko on 16.08.2023.
//

import Foundation

struct Contract: Encodable {
    let consumer: Consumer
    let provider: Provider
    let interactions: [Interaction]
    let metadata: Metadata
}

extension Contract {
    struct Consumer: Encodable {
        let name: String
    }

    struct Provider: Encodable {
        let name: String
    }

    struct Interaction: Encodable {
        let request: Request
        let response: Response
    }

    struct Request: Encodable {
        let method: String
        let path: String
        let query: MockQuery
    }

    struct Response: Encodable {
        let body: AnyEncodable
    }

    struct Metadata: Encodable {
        let pactRust: RustMetadata
        let pactSpecification: Version
    }

    struct Version: Encodable {
        let version: String
    }

    struct RustMetadata: Encodable {
        let mockserver: String
        let models: String
    }
}

