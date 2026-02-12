import Foundation
import XCTest
@testable import SelectAndSearchLLM

final class AnthropicProviderTests: XCTestCase {
    func testGenerateTextBuildsMessagesRequestAndParsesResponse() async throws {
        let client = AnthropicRecordingHTTPClient(
            data: """
            {
              "content": [
                {
                  "type": "text",
                  "text": "Anthropic answer"
                }
              ]
            }
            """.data(using: .utf8)!,
            statusCode: 200
        )
        let provider = AnthropicProvider(
            model: "claude-3-5-haiku-latest",
            apiKey: "anthropic-key",
            baseURL: URL(string: "https://api.anthropic.com")!,
            anthropicVersion: "2023-06-01",
            httpClient: client
        )

        let output = try await provider.generateText(
            input: LLMProviderInput(
                systemPrompt: "system",
                userPrompt: "user question",
                maxOutputTokens: 300,
                temperature: 0.3
            )
        )

        XCTAssertEqual(output, "Anthropic answer")
        let capturedRequest = await client.lastRequest()
        let request = try XCTUnwrap(capturedRequest)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "x-api-key"), "anthropic-key")
        XCTAssertEqual(request.value(forHTTPHeaderField: "anthropic-version"), "2023-06-01")
        XCTAssertTrue(request.url?.absoluteString.hasSuffix("/v1/messages") == true)
        let body = String(data: request.httpBody ?? Data(), encoding: .utf8) ?? ""
        XCTAssertTrue(body.contains("\"model\":\"claude-3-5-haiku-latest\""))
        XCTAssertTrue(body.contains("\"system\":\"system\""))
        XCTAssertTrue(body.contains("\"content\":\"user question\""))
    }

    func testGenerateTextFailsWhenAPIKeyMissing() async {
        let provider = AnthropicProvider(
            model: "claude-3-5-haiku-latest",
            apiKey: nil,
            baseURL: URL(string: "https://api.anthropic.com")!,
            anthropicVersion: "2023-06-01",
            httpClient: AnthropicRecordingHTTPClient(data: Data(), statusCode: 200)
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
            XCTAssertEqual(error, .missingAPIKey(provider: .anthropic, envVar: "ANTHROPIC_API_KEY"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private actor AnthropicRecordingHTTPClient: HTTPClient {
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
