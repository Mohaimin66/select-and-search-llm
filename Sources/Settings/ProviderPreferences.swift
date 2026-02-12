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
    var explainShortcut: KeyboardShortcut
    var askShortcut: KeyboardShortcut

    static let `default` = ProviderPreferences(
        selectedProvider: .gemini,
        geminiModel: "gemini-2.5-flash",
        anthropicModel: "claude-3-5-haiku-latest",
        anthropicBaseURL: "https://api.anthropic.com",
        anthropicVersion: "2023-06-01",
        openAIModel: "gpt-4.1-mini",
        localModel: "llama3.2:3b",
        localBaseURL: "http://localhost:11434",
        explainShortcut: .defaultExplain,
        askShortcut: .defaultAsk
    )

    private enum CodingKeys: String, CodingKey {
        case selectedProvider
        case geminiModel
        case anthropicModel
        case anthropicBaseURL
        case anthropicVersion
        case openAIModel
        case localModel
        case localBaseURL
        case explainShortcut
        case askShortcut
    }

    init(
        selectedProvider: LLMProviderKind,
        geminiModel: String,
        anthropicModel: String,
        anthropicBaseURL: String,
        anthropicVersion: String,
        openAIModel: String,
        localModel: String,
        localBaseURL: String,
        explainShortcut: KeyboardShortcut,
        askShortcut: KeyboardShortcut
    ) {
        self.selectedProvider = selectedProvider
        self.geminiModel = geminiModel
        self.anthropicModel = anthropicModel
        self.anthropicBaseURL = anthropicBaseURL
        self.anthropicVersion = anthropicVersion
        self.openAIModel = openAIModel
        self.localModel = localModel
        self.localBaseURL = localBaseURL
        self.explainShortcut = explainShortcut
        self.askShortcut = askShortcut
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = ProviderPreferences.default

        selectedProvider = try container.decodeIfPresent(LLMProviderKind.self, forKey: .selectedProvider) ?? defaults.selectedProvider
        geminiModel = try container.decodeIfPresent(String.self, forKey: .geminiModel) ?? defaults.geminiModel
        anthropicModel = try container.decodeIfPresent(String.self, forKey: .anthropicModel) ?? defaults.anthropicModel
        anthropicBaseURL = try container.decodeIfPresent(String.self, forKey: .anthropicBaseURL) ?? defaults.anthropicBaseURL
        anthropicVersion = try container.decodeIfPresent(String.self, forKey: .anthropicVersion) ?? defaults.anthropicVersion
        openAIModel = try container.decodeIfPresent(String.self, forKey: .openAIModel) ?? defaults.openAIModel
        localModel = try container.decodeIfPresent(String.self, forKey: .localModel) ?? defaults.localModel
        localBaseURL = try container.decodeIfPresent(String.self, forKey: .localBaseURL) ?? defaults.localBaseURL
        explainShortcut = try container.decodeIfPresent(KeyboardShortcut.self, forKey: .explainShortcut) ?? defaults.explainShortcut
        askShortcut = try container.decodeIfPresent(KeyboardShortcut.self, forKey: .askShortcut) ?? defaults.askShortcut
    }
}
