import Foundation

struct GeminiProvider: LLMProvider {
    let kind: LLMProviderKind = .gemini

    private let model: String
    private let apiKey: String?
    private let httpClient: any HTTPClient

    init(
        model: String,
        apiKey: String?,
        httpClient: any HTTPClient
    ) {
        self.model = model
        self.apiKey = apiKey
        self.httpClient = httpClient
    }

    func generateText(input: LLMProviderInput) async throws -> String {
        guard let apiKey, !apiKey.isEmpty else {
            throw LLMProviderError.missingAPIKey(provider: kind, envVar: "GEMINI_API_KEY")
        }

        var components = URLComponents(
            string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent"
        )
        components?.queryItems = [URLQueryItem(name: "key", value: apiKey)]

        guard let url = components?.url else {
            throw LLMProviderError.invalidResponse
        }

        let prompt = [input.systemPrompt, input.userPrompt]
            .compactMap { $0 }
            .joined(separator: "\n\n")
        let requestBody = GeminiGenerateRequest(
            contents: [
                .init(parts: [.init(text: prompt)])
            ],
            generationConfig: .init(
                temperature: input.temperature,
                maxOutputTokens: input.maxOutputTokens
            )
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await httpClient.data(for: request)
        try validate(response: response, data: data)

        let decoded = try JSONDecoder().decode(GeminiGenerateResponse.self, from: data)
        let text = decoded.candidates
            .flatMap { $0.content.parts }
            .compactMap(\.text)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            throw LLMProviderError.emptyResponse
        }

        return text
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
            let decoded = try? JSONDecoder().decode(GeminiErrorEnvelope.self, from: data),
            let message = decoded.error?.message?.trimmingCharacters(in: .whitespacesAndNewlines),
            !message.isEmpty
        else {
            return nil
        }

        return message
    }
}

private struct GeminiGenerateRequest: Encodable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
}

private struct GeminiContent: Encodable {
    let parts: [GeminiPart]
}

private struct GeminiPart: Encodable {
    let text: String
}

private struct GeminiGenerationConfig: Encodable {
    let temperature: Double?
    let maxOutputTokens: Int?
}

private struct GeminiGenerateResponse: Decodable {
    let candidates: [GeminiCandidate]
}

private struct GeminiCandidate: Decodable {
    let content: GeminiCandidateContent
}

private struct GeminiCandidateContent: Decodable {
    let parts: [GeminiCandidatePart]
}

private struct GeminiCandidatePart: Decodable {
    let text: String?
}

private struct GeminiErrorEnvelope: Decodable {
    let error: GeminiErrorPayload?
}

private struct GeminiErrorPayload: Decodable {
    let message: String?
}
