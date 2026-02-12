import XCTest
@testable import SelectAndSearchLLM

final class LLMProviderFactoryTests: XCTestCase {
    func testEnvironmentDefaultsToGemini() {
        let config = LLMProviderRuntimeConfiguration.fromEnvironment([:])
        XCTAssertEqual(config.defaultProvider, .gemini)
        XCTAssertEqual(config.geminiModel, "gemini-2.5-flash")
        XCTAssertEqual(config.anthropicModel, "claude-3-5-haiku-latest")
        XCTAssertEqual(config.anthropicBaseURL.absoluteString, "https://api.anthropic.com")
        XCTAssertEqual(config.anthropicVersion, "2023-06-01")
        XCTAssertEqual(config.localModel, "llama3.2:3b")
        XCTAssertEqual(config.localBaseURL.absoluteString, "http://localhost:11434")
    }

    func testEnvironmentParsesProviderAndBaseURL() {
        let config = LLMProviderRuntimeConfiguration.fromEnvironment([
            "SELECT_AND_SEARCH_PROVIDER": "local",
            "LOCAL_LLM_BASE_URL": "http://localhost:1234/v1",
            "LOCAL_LLM_MODEL": "gemma2:2b"
        ])

        XCTAssertEqual(config.defaultProvider, .local)
        XCTAssertEqual(config.localModel, "gemma2:2b")
        XCTAssertEqual(config.localBaseURL.absoluteString, "http://localhost:1234/v1")
    }

    func testFactoryBuildsOpenAIProviderFromConfiguration() {
        let config = LLMProviderRuntimeConfiguration.fromEnvironment([
            "SELECT_AND_SEARCH_PROVIDER": "openai",
            "OPENAI_MODEL": "gpt-4.1-mini",
            "OPENAI_API_KEY": "key"
        ])

        let provider = LLMProviderFactory.makeProvider(
            configuration: config,
            httpClient: StubHTTPClient()
        )

        XCTAssertEqual(provider.kind, .openAI)
    }

    func testFactoryBuildsAnthropicProviderFromConfiguration() {
        let config = LLMProviderRuntimeConfiguration.fromEnvironment([
            "SELECT_AND_SEARCH_PROVIDER": "anthropic",
            "ANTHROPIC_MODEL": "claude-3-5-haiku-latest",
            "ANTHROPIC_API_KEY": "key"
        ])

        let provider = LLMProviderFactory.makeProvider(
            configuration: config,
            httpClient: StubHTTPClient()
        )

        XCTAssertEqual(provider.kind, .anthropic)
    }
}

private struct StubHTTPClient: HTTPClient {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let response = HTTPURLResponse(
            url: request.url ?? URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return (Data(), response)
    }
}
