import Foundation
import XCTest
@testable import SelectAndSearchLLM

final class GeminiProviderTests: XCTestCase {
    func testGenerateTextBuildsGeminiRequestAndParsesResponse() async throws {
        let client = RecordingHTTPClient(
            data: """
            {
              "candidates": [
                {
                  "content": {
                    "parts": [
                      { "text": "Explained text" }
                    ]
                  }
                }
              ]
            }
            """.data(using: .utf8)!,
            statusCode: 200
        )
        let provider = GeminiProvider(
            model: "gemini-2.5-flash",
            apiKey: "test-key",
            httpClient: client
        )

        let result = try await provider.generateText(
            input: LLMProviderInput(
                systemPrompt: "System",
                userPrompt: "User",
                maxOutputTokens: 128,
                temperature: 0.2
            )
        )

        XCTAssertEqual(result, "Explained text")
        let capturedRequest = await client.lastRequest()
        let request = try XCTUnwrap(capturedRequest)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertTrue(request.url?.absoluteString.contains("generativelanguage.googleapis.com") == true)
        XCTAssertTrue(request.url?.absoluteString.contains("key=test-key") == true)
        let body = String(data: request.httpBody ?? Data(), encoding: .utf8) ?? ""
        XCTAssertTrue(body.contains("System"))
        XCTAssertTrue(body.contains("User"))
    }

    func testGenerateTextFailsWhenAPIKeyMissing() async {
        let provider = GeminiProvider(
            model: "gemini-2.5-flash",
            apiKey: nil,
            httpClient: RecordingHTTPClient(data: Data(), statusCode: 200)
        )

        do {
            _ = try await provider.generateText(
                input: LLMProviderInput(
                    systemPrompt: nil,
                    userPrompt: "hello",
                    maxOutputTokens: nil,
                    temperature: nil
                )
            )
            XCTFail("Expected error")
        } catch let error as LLMProviderError {
            XCTAssertEqual(error, .missingAPIKey(provider: .gemini, envVar: "GEMINI_API_KEY"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private actor RecordingHTTPClient: HTTPClient {
    private let data: Data
    private let statusCode: Int
    private var capturedRequest: URLRequest?

    init(data: Data, statusCode: Int) {
        self.data = data
        self.statusCode = statusCode
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        capturedRequest = request
        let response = HTTPURLResponse(
            url: request.url ?? URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (data, response)
    }

    func lastRequest() -> URLRequest? {
        capturedRequest
    }
}
