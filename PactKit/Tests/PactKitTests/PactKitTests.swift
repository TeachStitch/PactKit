import XCTest
@testable import PactKit

final class PactKitTests: XCTestCase {
    let mockService = MockComponent.shared
    let networkClient = NetworkClient()

    private var port: Int32 = 0

    override func tearDown() {
        super.tearDown()
        mockService.shutdown(on: port)
    }

    func testMockService() throws {
        let expectation = expectation(description: #function)

        let serverData = try mockService.setupServer(
            on: 5050,
            with: [
                "/test": (
                    data: AnyEncodable(TestModel(name: "Test", age: 30)),
                    method: "GET",
                    query: [:]
                )
            ]
        )

        var request = URLRequest(url: URL(string: "\(serverData.baseURL)/test")!)
        request.httpMethod = "GET"

        networkClient.perform(with: request) { data, response, error in
            guard let data = data, error == nil else {
                XCTFail("Failed with \(String(describing: error))")
                return
            }

            do {
                _ = try XCTUnwrap(try JSONDecoder().decode(TestModel.self, from: data))

                XCTAssertEqual(serverData.port, 5050)
                XCTAssertEqual(serverData.baseURL, "https://127.0.0.1:5050")

                expectation.fulfill()
            } catch {
                XCTFail("Expected PageResponse.")
            }
        }

        port = serverData.port

        wait(for: [expectation], timeout: 1)
    }
}

struct TestModel: Codable {
    let name: String
    let age: Int
}
