import Foundation

struct OpenAICompatibleProvider: LLMProvider {
    let kind: LLMProviderKind

    private let model: String
    private let baseURL: URL
    private let apiKey: String?
    private let requiresAPIKey: Bool
    private let missingKeyEnvVar: String
    private let httpClient: any HTTPClient

    init(
        kind: LLMProviderKind,
        model: String,
        baseURL: URL,
        apiKey: String?,
        requiresAPIKey: Bool,
        missingKeyEnvVar: String,
        httpClient: any HTTPClient
    ) {
        self.kind = kind
        self.model = model
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.requiresAPIKey = requiresAPIKey
        self.missingKeyEnvVar = missingKeyEnvVar
        self.httpClient = httpClient
    }

    func generateText(input: LLMProviderInput) async throws -> String {
        if requiresAPIKey, (apiKey == nil || apiKey?.isEmpty == true) {
            throw LLMProviderError.missingAPIKey(provider: kind, envVar: missingKeyEnvVar)
        }

        let requestBody = OpenAIChatCompletionsRequest(
            model: model,
            messages: buildMessages(for: input),
            maxTokens: input.maxOutputTokens,
            temperature: input.temperature
        )

        var request = URLRequest(url: chatCompletionsURL())
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await httpClient.data(for: request)
        try validate(response: response, data: data)

        let decoded = try JSONDecoder().decode(OpenAIChatCompletionsResponse.self, from: data)
        let text = decoded.choices
            .compactMap { $0.message.content }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            throw LLMProviderError.emptyResponse
        }

        return text
    }

    private func buildMessages(for input: LLMProviderInput) -> [OpenAIChatMessage] {
        var messages: [OpenAIChatMessage] = []
        if let systemPrompt = input.systemPrompt, !systemPrompt.isEmpty {
            messages.append(.init(role: "system", content: systemPrompt))
        }
        messages.append(.init(role: "user", content: input.userPrompt))
        return messages
    }

    private func chatCompletionsURL() -> URL {
        let normalizedPath = baseURL.path.lowercased()
        if normalizedPath.hasSuffix("/v1/chat/completions") {
            return baseURL
        }
        if normalizedPath.hasSuffix("/v1") {
            return baseURL.appendingPathComponent("chat/completions")
        }
        return baseURL.appendingPathComponent("v1/chat/completions")
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
            let decoded = try? JSONDecoder().decode(OpenAIErrorEnvelope.self, from: data),
            let message = decoded.error?.message?.trimmingCharacters(in: .whitespacesAndNewlines),
            !message.isEmpty
        else {
            return nil
        }
        return message
    }
}

private struct OpenAIChatCompletionsRequest: Encodable {
    let model: String
    let messages: [OpenAIChatMessage]
    let maxTokens: Int?
    let temperature: Double?

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case maxTokens = "max_tokens"
        case temperature
    }
}

private struct OpenAIChatMessage: Codable {
    let role: String
    let content: String
}

private struct OpenAIChatCompletionsResponse: Decodable {
    let choices: [OpenAIChatChoice]
}

private struct OpenAIChatChoice: Decodable {
    let message: OpenAIChatResponseMessage
}

private struct OpenAIChatResponseMessage: Decodable {
    let content: String?
}

private struct OpenAIErrorEnvelope: Decodable {
    let error: OpenAIErrorPayload?
}

private struct OpenAIErrorPayload: Decodable {
    let message: String?
}
