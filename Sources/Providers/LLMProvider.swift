import Foundation

enum LLMProviderKind: String, CaseIterable, Codable, Equatable, Sendable {
    case gemini
    case anthropic
    case openAI = "openai"
    case local
}

struct LLMProviderInput: Equatable, Sendable {
    let systemPrompt: String?
    let userPrompt: String
    let maxOutputTokens: Int?
    let temperature: Double?
}

protocol LLMProvider: Sendable {
    var kind: LLMProviderKind { get }
    func generateText(input: LLMProviderInput) async throws -> String
}

enum LLMProviderError: Error, Equatable, Sendable {
    case missingAPIKey(provider: LLMProviderKind, envVar: String)
    case invalidResponse
    case httpStatus(Int, String?)
    case emptyResponse
}

extension LLMProviderError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .missingAPIKey(provider, envVar):
            return "Missing API key for \(provider.displayName). Set \(envVar)."
        case let .httpStatus(status, message):
            if let message, !message.isEmpty {
                return "Provider request failed (\(status)): \(message)"
            }
            return "Provider request failed (\(status))."
        case .invalidResponse:
            return "Provider returned an invalid response."
        case .emptyResponse:
            return "Provider returned an empty response."
        }
    }
}

extension LLMProviderKind {
    var displayName: String {
        switch self {
        case .gemini:
            return "Gemini"
        case .anthropic:
            return "Anthropic"
        case .openAI:
            return "OpenAI"
        case .local:
            return "Local"
        }
    }

    static func parse(_ value: String?) -> LLMProviderKind? {
        let normalized = value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch normalized {
        case "gemini":
            return .gemini
        case "anthropic", "claude":
            return .anthropic
        case "openai", "open_ai":
            return .openAI
        case "local", "ollama", "lmstudio", "lm_studio":
            return .local
        default:
            return nil
        }
    }
}

struct LLMProviderRuntimeConfiguration: Equatable, Sendable {
    let defaultProvider: LLMProviderKind
    let geminiModel: String
    let geminiAPIKey: String?
    let anthropicModel: String
    let anthropicAPIKey: String?
    let anthropicBaseURL: URL
    let anthropicVersion: String
    let openAIModel: String
    let openAIAPIKey: String?
    let localModel: String
    let localBaseURL: URL
    let localAPIKey: String?

    static func fromEnvironment(_ environment: [String: String] = ProcessInfo.processInfo.environment) -> Self {
        let provider = LLMProviderKind.parse(environment["SELECT_AND_SEARCH_PROVIDER"]) ?? .gemini

        return Self(
            defaultProvider: provider,
            geminiModel: normalizedValue(environment["GEMINI_MODEL"]) ?? "gemini-2.5-flash",
            geminiAPIKey: normalizedValue(environment["GEMINI_API_KEY"]),
            anthropicModel: normalizedValue(environment["ANTHROPIC_MODEL"]) ?? "claude-3-5-haiku-latest",
            anthropicAPIKey: normalizedValue(environment["ANTHROPIC_API_KEY"]),
            anthropicBaseURL: anthropicBaseURL(from: environment),
            anthropicVersion: normalizedValue(environment["ANTHROPIC_VERSION"]) ?? "2023-06-01",
            openAIModel: normalizedValue(environment["OPENAI_MODEL"]) ?? "gpt-4.1-mini",
            openAIAPIKey: normalizedValue(environment["OPENAI_API_KEY"]),
            localModel: normalizedValue(environment["LOCAL_LLM_MODEL"]) ?? "llama3.2:3b",
            localBaseURL: localBaseURL(from: environment),
            localAPIKey: normalizedValue(environment["LOCAL_LLM_API_KEY"])
        )
    }

    private static func normalizedValue(_ raw: String?) -> String? {
        guard let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private static func localBaseURL(from environment: [String: String]) -> URL {
        if
            let value = normalizedValue(environment["LOCAL_LLM_BASE_URL"]),
            let url = URL(string: value)
        {
            return url
        }

        return URL(string: "http://localhost:11434")!
    }

    private static func anthropicBaseURL(from environment: [String: String]) -> URL {
        if
            let value = normalizedValue(environment["ANTHROPIC_BASE_URL"]),
            let url = URL(string: value)
        {
            return url
        }

        return URL(string: "https://api.anthropic.com")!
    }
}

enum LLMProviderFactory {
    static func makeProvider(
        configuration: LLMProviderRuntimeConfiguration = .fromEnvironment(),
        httpClient: any HTTPClient = URLSessionHTTPClient()
    ) -> any LLMProvider {
        switch configuration.defaultProvider {
        case .gemini:
            return GeminiProvider(
                model: configuration.geminiModel,
                apiKey: configuration.geminiAPIKey,
                httpClient: httpClient
            )
        case .anthropic:
            return AnthropicProvider(
                model: configuration.anthropicModel,
                apiKey: configuration.anthropicAPIKey,
                baseURL: configuration.anthropicBaseURL,
                anthropicVersion: configuration.anthropicVersion,
                httpClient: httpClient
            )
        case .openAI:
            return OpenAICompatibleProvider(
                kind: .openAI,
                model: configuration.openAIModel,
                baseURL: URL(string: "https://api.openai.com")!,
                apiKey: configuration.openAIAPIKey,
                requiresAPIKey: true,
                missingKeyEnvVar: "OPENAI_API_KEY",
                httpClient: httpClient
            )
        case .local:
            return OpenAICompatibleProvider(
                kind: .local,
                model: configuration.localModel,
                baseURL: configuration.localBaseURL,
                apiKey: configuration.localAPIKey,
                requiresAPIKey: false,
                missingKeyEnvVar: "LOCAL_LLM_API_KEY",
                httpClient: httpClient
            )
        }
    }
}
