//
//  MockComponent.swift
//  
//
//  Created by Arsenii Kovalenko on 16.08.2023.
//

import UIKit
import PactSwiftMockServer

public typealias MockQuery = [String: [String]]
public typealias MockResponses = [String: (data: AnyEncodable, method: String, query: MockQuery)]

// MockComponent entry point
public final class MockComponent {

    public static let shared = MockComponent()

    /// Finds an unsued port on Darwin. Returns ``0`` on Linux.
    private static var randomPort: Int32 {
        #if os(Linux)
        return 0
        #else
        // Darwin doesn't seem to use a random available port if ``0`` is sent to pactffi_create_mock_server(_:_:_:)
        return SocketBinder.unusedPort()
        #endif
    }

    private let socketAddress = "127.0.0.1"

    private init() {}

    /// Setup function that map passed responces into `pact_ffi` as a payload and initialize mock server on port.
    /// - Parameters:
    ///   - port: server's port. In case of `nil` random unused port will be used.
    ///   - responses: Dictionary that represents mocked responses. (Key is string URL path without query params. Value includes `URL method`, `query params`, `data`.)
    public func setupServer(on port: Int32?, with responses: MockResponses) throws -> MockServerData {

        let mapped = map(responses)
        let data = try JSONEncoder().encode(mapped)
        let url = "\(socketAddress):\(port ?? Self.randomPort)"

        let stringEncoded = String(data: data, encoding: .utf8)

        let serverPort = pactffi_create_mock_server(stringEncoded, url, true)

        return MockServerData(
            baseURL: "https://\(url)",
            port: serverPort
        )
    }

    public func setupServerOnUI(parent: UIViewController, completion: @escaping (MockServerData?) -> Void) {
        let configurator = MockConfigurator { [unowned self] data in
            completion(try? setupServer(on: nil, with: reduce(data)))
        }
        
        parent.present(UINavigationController(rootViewController: configurator), animated: true)
    }

    /// Shutdowns server on port.
    /// - Parameters:
    ///   - port: server's port.
    public func shutdown(on port: Int32) {
        pactffi_cleanup_mock_server(port)
    }

    private func map(_ responses: MockResponses) -> Contract {
        let interactions: [Contract.Interaction] = responses.map { path, value in
            Contract.Interaction(
                request: Contract.Request(
                    method: value.method,
                    path: path,
                    query: value.query
                ),
                response: Contract.Response(body: value.data)
            )
        }

        return Contract(
            consumer: Contract.Consumer(name: "mock-consumer"),
            provider: Contract.Provider(name: "mock-provider"),
            interactions: interactions,
            metadata: Contract.Metadata(
                pactRust: Contract.RustMetadata(
                    mockserver: "0.9.4",
                    models: "0.4.5"
                ),
                pactSpecification: Contract.Version(
                    version: "3.0.0"
                )
            )
        )
    }

    private func reduce(_ data: [MockedEndpoint]) -> MockResponses {
        data.reduce(into: MockResponses()) { result, endpoint in
            result[endpoint.path] = (
                data: endpoint.data,
                method: endpoint.method,
                query: endpoint.query
            )
        }
    }
}

