import Foundation
import XCTest
@testable import SelectAndSearchLLM

final class OpenAICompatibleProviderTests: XCTestCase {
    func testGenerateTextSendsAuthForRemoteProvider() async throws {
        let client = OpenAIRecordingHTTPClient(
            data: """
            {
              "choices": [
                {
                  "message": {
                    "content": "Remote answer"
                  }
                }
              ]
            }
            """.data(using: .utf8)!,
            statusCode: 200
        )
        let provider = OpenAICompatibleProvider(
            kind: .openAI,
            model: "gpt-4.1-mini",
            baseURL: URL(string: "https://api.openai.com")!,
            apiKey: "openai-key",
            requiresAPIKey: true,
            missingKeyEnvVar: "OPENAI_API_KEY",
            httpClient: client
        )

        let output = try await provider.generateText(
            input: LLMProviderInput(
                systemPrompt: "system",
                userPrompt: "user",
                maxOutputTokens: 200,
                temperature: 0.4
            )
        )

        XCTAssertEqual(output, "Remote answer")
        let capturedRequest = await client.lastRequest()
        let request = try XCTUnwrap(capturedRequest)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer openai-key")
        XCTAssertTrue(request.url?.absoluteString.hasSuffix("/v1/chat/completions") == true)
    }

    func testGenerateTextDoesNotRequireAuthForLocalProvider() async throws {
        let client = OpenAIRecordingHTTPClient(
            data: """
            {
              "choices": [
                {
                  "message": {
                    "content": "Local answer"
                  }
                }
              ]
            }
            """.data(using: .utf8)!,
            statusCode: 200
        )
        let provider = OpenAICompatibleProvider(
            kind: .local,
            model: "llama3.2:3b",
            baseURL: URL(string: "http://localhost:11434")!,
            apiKey: nil,
            requiresAPIKey: false,
            missingKeyEnvVar: "LOCAL_LLM_API_KEY",
            httpClient: client
        )

        let output = try await provider.generateText(
            input: LLMProviderInput(
                systemPrompt: nil,
                userPrompt: "user",
                maxOutputTokens: nil,
                temperature: nil
            )
        )

        XCTAssertEqual(output, "Local answer")
        let capturedRequest = await client.lastRequest()
        let request = try XCTUnwrap(capturedRequest)
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
    }

    func testGenerateTextFailsWhenRequiredAPIKeyMissing() async {
        let provider = OpenAICompatibleProvider(
            kind: .openAI,
            model: "gpt-4.1-mini",
            baseURL: URL(string: "https://api.openai.com")!,
            apiKey: nil,
            requiresAPIKey: true,
            missingKeyEnvVar: "OPENAI_API_KEY",
            httpClient: OpenAIRecordingHTTPClient(data: Data(), statusCode: 200)
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
            XCTAssertEqual(error, .missingAPIKey(provider: .openAI, envVar: "OPENAI_API_KEY"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testGenerateTextUsesCorrectEndpointWhenBaseURLEndsWithV1Slash() async throws {
        let client = OpenAIRecordingHTTPClient(
            data: """
            {
              "choices": [
                {
                  "message": {
                    "content": "OK"
                  }
                }
              ]
            }
            """.data(using: .utf8)!,
            statusCode: 200
        )
        let provider = OpenAICompatibleProvider(
            kind: .openAI,
            model: "gpt-4.1-mini",
            baseURL: URL(string: "https://api.openai.com/v1/")!,
            apiKey: "openai-key",
            requiresAPIKey: true,
            missingKeyEnvVar: "OPENAI_API_KEY",
            httpClient: client
        )

        _ = try await provider.generateText(
            input: LLMProviderInput(
                systemPrompt: nil,
                userPrompt: "user",
                maxOutputTokens: nil,
                temperature: nil
            )
        )

        let capturedRequest = await client.lastRequest()
        let request = try XCTUnwrap(capturedRequest)
        XCTAssertEqual(request.url?.absoluteString, "https://api.openai.com/v1/chat/completions")
    }

    func testGenerateTextUsesCorrectEndpointWhenBaseURLEndsWithCompletionsSlash() async throws {
        let client = OpenAIRecordingHTTPClient(
            data: """
            {
              "choices": [
                {
                  "message": {
                    "content": "OK"
                  }
                }
              ]
            }
            """.data(using: .utf8)!,
            statusCode: 200
        )
        let provider = OpenAICompatibleProvider(
            kind: .openAI,
            model: "gpt-4.1-mini",
            baseURL: URL(string: "https://api.openai.com/v1/chat/completions/")!,
            apiKey: "openai-key",
            requiresAPIKey: true,
            missingKeyEnvVar: "OPENAI_API_KEY",
            httpClient: client
        )

        _ = try await provider.generateText(
            input: LLMProviderInput(
                systemPrompt: nil,
                userPrompt: "user",
                maxOutputTokens: nil,
                temperature: nil
            )
        )

        let capturedRequest = await client.lastRequest()
        let request = try XCTUnwrap(capturedRequest)
        XCTAssertEqual(request.url?.absoluteString, "https://api.openai.com/v1/chat/completions")
    }
}

private actor OpenAIRecordingHTTPClient: HTTPClient {
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
