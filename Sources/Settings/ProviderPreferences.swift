import Foundation

struct ProviderPreferences: Equatable, Codable, Sendable {
    var selectedProvider: LLMProviderKind
    var geminiModel: String
    var anthropicModel: String
    var anthropicBaseURL: String
    var anthropicVersion: String
    var openAIModel: String
    var localModel: String
    var localBaseURL: String

    static let `default` = ProviderPreferences(
        selectedProvider: .gemini,
        geminiModel: "gemini-2.5-flash",
        anthropicModel: "claude-3-5-haiku-latest",
        anthropicBaseURL: "https://api.anthropic.com",
        anthropicVersion: "2023-06-01",
        openAIModel: "gpt-4.1-mini",
        localModel: "llama3.2:3b",
        localBaseURL: "http://localhost:11434"
    )
}
