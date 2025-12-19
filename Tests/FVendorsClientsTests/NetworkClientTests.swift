import FVendorsClients
import Foundation
import FVendorsModels
import Testing

@Suite("NetworkClient Tests")
struct NetworkClientTests {
    // MARK: - 基础接口测试

    @Test("Mock client interface is accessible")
    func mockClientInterfaceAccessible() async throws {
        let client = NetworkClient.mock { _ in
            Data()
        }

        let url = URL(string: "https://api.example.com/test")!
        let request = URLRequest(url: url)
        let data = try await client.request(request)

        #expect(data.isEmpty)
    }

    @Test("Noop client returns empty data")
    func noopClientReturnsEmptyData() async throws {
        let client = NetworkClient.noop

        let url = URL(string: "https://api.example.com/test")!
        let request = URLRequest(url: url)
        let data = try await client.request(request)

        #expect(data.isEmpty)
    }

    // MARK: - 成功请求测试

    @Test("Mock client can return custom data")
    func mockClientReturnsCustomData() async throws {
        let expectedData = "Hello, World!".data(using: .utf8)!
        let client = NetworkClient.mock { _ in
            expectedData
        }

        let url = URL(string: "https://api.example.com/test")!
        let request = URLRequest(url: url)
        let data = try await client.request(request)

        #expect(data == expectedData)
    }

    @Test("Request with decoding returns correct object")
    func requestWithDecodingReturnsCorrectObject() async throws {
        struct TestResponse: Codable, Equatable {
            let message: String
            let count: Int
        }

        let expectedResponse = TestResponse(message: "success", count: 42)
        let jsonData = try JSONEncoder().encode(expectedResponse)

        let client = NetworkClient.mock { _ in
            jsonData
        }

        let url = URL(string: "https://api.example.com/test")!
        let request = URLRequest(url: url)
        let response = try await client.request(request, as: TestResponse.self)

        #expect(response == expectedResponse)
    }

    // MARK: - 错误处理测试

    @Test("Request with decoding throws on invalid JSON")
    func requestWithDecodingThrowsOnInvalidJSON() async throws {
        struct TestResponse: Codable {
            let message: String
        }

        let invalidData = "{ invalid json }".data(using: .utf8)!
        let client = NetworkClient.mock { _ in
            invalidData
        }

        let url = URL(string: "https://api.example.com/test")!
        let request = URLRequest(url: url)

        do {
            _ = try await client.request(request, as: TestResponse.self)
            Issue.record("Should have thrown decoding error")
        } catch let error as AppError {
            guard case .networkError(let reason) = error else {
                Issue.record("Expected networkError, got \(error)")
                return
            }
            guard case .decodingFailed = reason else {
                Issue.record("Expected decodingFailed, got \(reason)")
                return
            }
            // 测试通过
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Mock client can throw custom errors")
    func mockClientCanThrowCustomErrors() async throws {
        let client = NetworkClient.mock { _ in
            throw AppError.networkError(.noConnection)
        }

        let url = URL(string: "https://api.example.com/test")!
        let request = URLRequest(url: url)

        do {
            _ = try await client.request(request)
            Issue.record("Should have thrown error")
        } catch let error as AppError {
            guard case .networkError(let reason) = error else {
                Issue.record("Expected networkError")
                return
            }
            guard case .noConnection = reason else {
                Issue.record("Expected noConnection")
                return
            }
            // 测试通过
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    // MARK: - APIRequestBuilder 测试

    @Test("APIRequestBuilder creates GET request correctly")
    func requestBuilderCreatesGETRequest() {
        let url = URL(string: "https://api.example.com/users")!
        let request = APIRequestBuilder.buildRequest(
            url: url,
            method: .get,
            headers: ["Authorization": "Bearer token"]
        )

        #expect(request.url == url)
        #expect(request.httpMethod == "GET")
        #expect(request.allHTTPHeaderFields?["Authorization"] == "Bearer token")
        #expect(request.httpBody == nil)
    }

    @Test("APIRequestBuilder creates POST request with body")
    func requestBuilderCreatesPOSTRequest() {
        let url = URL(string: "https://api.example.com/users")!
        let bodyData = "test body".data(using: .utf8)!
        let request = APIRequestBuilder.buildRequest(
            url: url,
            method: .post,
            headers: ["Content-Type": "application/json"],
            body: bodyData
        )

        #expect(request.url == url)
        #expect(request.httpMethod == "POST")
        #expect(request.allHTTPHeaderFields?["Content-Type"] == "application/json")
        #expect(request.httpBody == bodyData)
    }

    @Test("APIRequestBuilder creates JSON request")
    func requestBuilderCreatesJSONRequest() throws {
        struct TestRequest: Codable {
            let name: String
            let age: Int
        }

        let url = URL(string: "https://api.example.com/users")!
        let body = TestRequest(name: "Alice", age: 30)
        let request = try APIRequestBuilder.buildJSONRequest(
            url: url,
            method: .post,
            body: body
        )

        #expect(request.url == url)
        #expect(request.httpMethod == "POST")
        #expect(request.allHTTPHeaderFields?["Content-Type"] == "application/json")
        #expect(request.httpBody != nil)

        // 验证 JSON 编码正确
        let decoded = try JSONDecoder().decode(TestRequest.self, from: request.httpBody!)
        #expect(decoded.name == "Alice")
        #expect(decoded.age == 30)
    }

    @Test("APIRequestBuilder merges headers in JSON request")
    func requestBuilderMergesHeadersInJSONRequest() throws {
        struct TestRequest: Codable {
            let value: String
        }

        let url = URL(string: "https://api.example.com/test")!
        let body = TestRequest(value: "test")
        let request = try APIRequestBuilder.buildJSONRequest(
            url: url,
            body: body,
            headers: ["Authorization": "Bearer token", "X-Custom": "value"]
        )

        #expect(request.allHTTPHeaderFields?["Content-Type"] == "application/json")
        #expect(request.allHTTPHeaderFields?["Authorization"] == "Bearer token")
        #expect(request.allHTTPHeaderFields?["X-Custom"] == "value")
    }
}
