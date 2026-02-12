import Foundation

struct AnthropicProvider: LLMProvider {
    let kind: LLMProviderKind = .anthropic

    private let model: String
    private let apiKey: String?
    private let baseURL: URL
    private let anthropicVersion: String
    private let httpClient: any HTTPClient

    init(
        model: String,
        apiKey: String?,
        baseURL: URL,
        anthropicVersion: String,
        httpClient: any HTTPClient
    ) {
        self.model = model
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.anthropicVersion = anthropicVersion
        self.httpClient = httpClient
    }

    func generateText(input: LLMProviderInput) async throws -> String {
        guard let apiKey, !apiKey.isEmpty else {
            throw LLMProviderError.missingAPIKey(provider: kind, envVar: "ANTHROPIC_API_KEY")
        }

        let requestBody = AnthropicMessagesRequest(
            model: model,
            maxTokens: input.maxOutputTokens ?? 420,
            temperature: input.temperature,
            system: input.systemPrompt,
            messages: [
                .init(role: "user", content: input.userPrompt)
            ]
        )

        var request = URLRequest(url: messagesURL())
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await httpClient.data(for: request)
        try validate(response: response, data: data)

        let decoded = try JSONDecoder().decode(AnthropicMessagesResponse.self, from: data)
        let text = decoded.content
            .filter { $0.type == "text" }
            .map(\.text)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            throw LLMProviderError.emptyResponse
        }

        return text
    }

    private func messagesURL() -> URL {
        let normalizedPath = baseURL.path.lowercased()
        if normalizedPath.hasSuffix("/v1/messages") {
            return baseURL
        }
        if normalizedPath.hasSuffix("/v1") {
            return baseURL.appendingPathComponent("messages")
        }
        return baseURL.appendingPathComponent("v1/messages")
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw LLMProviderError.invalidResponse
        }

        guard (200 ... 299).contains(http.statusCode) else {
            let message = parseErrorMessage(from: data)
            throw LLMProviderError.httpStatus(http.statusCode, message)
        }
    }

    private func parseErrorMessage(from data: Data) -> String? {
        guard
            let decoded = try? JSONDecoder().decode(AnthropicErrorEnvelope.self, from: data),
            let message = decoded.error?.message?.trimmingCharacters(in: .whitespacesAndNewlines),
            !message.isEmpty
        else {
            return nil
        }
        return message
    }
}

private struct AnthropicMessagesRequest: Encodable {
    let model: String
    let maxTokens: Int
    let temperature: Double?
    let system: String?
    let messages: [AnthropicMessage]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case temperature
        case system
        case messages
    }
}

private struct AnthropicMessage: Encodable {
    let role: String
    let content: String
}

private struct AnthropicMessagesResponse: Decodable {
    let content: [AnthropicContentBlock]
}

private struct AnthropicContentBlock: Decodable {
    let type: String
    let text: String
}

private struct AnthropicErrorEnvelope: Decodable {
    let error: AnthropicErrorPayload?
}

private struct AnthropicErrorPayload: Decodable {
    let message: String?
}
