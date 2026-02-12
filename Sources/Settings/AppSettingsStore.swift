import Combine
import Foundation

@MainActor
final class AppSettingsStore: ObservableObject {
    @Published var preferences: ProviderPreferences {
        didSet {
            guard !isLoading else { return }
            persistPreferences()
        }
    }

    @Published var geminiAPIKey: String {
        didSet {
            persistSecret(geminiAPIKey, account: SecretAccount.gemini)
        }
    }

    @Published var anthropicAPIKey: String {
        didSet {
            persistSecret(anthropicAPIKey, account: SecretAccount.anthropic)
        }
    }

    @Published var openAIAPIKey: String {
        didSet {
            persistSecret(openAIAPIKey, account: SecretAccount.openAI)
        }
    }

    @Published var localAPIKey: String {
        didSet {
            persistSecret(localAPIKey, account: SecretAccount.local)
        }
    }

    @Published private(set) var lastSaveErrorMessage: String?

    private let userDefaults: UserDefaults
    private let keychain: any KeychainValueStoring
    private var isLoading = false

    init(
        userDefaults: UserDefaults = .standard,
        keychain: any KeychainValueStoring = KeychainService()
    ) {
        self.userDefaults = userDefaults
        self.keychain = keychain

        isLoading = true
        preferences = Self.loadPreferences(from: userDefaults)
        geminiAPIKey = keychain.string(for: SecretAccount.gemini) ?? ""
        anthropicAPIKey = keychain.string(for: SecretAccount.anthropic) ?? ""
        openAIAPIKey = keychain.string(for: SecretAccount.openAI) ?? ""
        localAPIKey = keychain.string(for: SecretAccount.local) ?? ""
        isLoading = false
    }

    func runtimeConfiguration(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> LLMProviderRuntimeConfiguration {
        let envConfig = LLMProviderRuntimeConfiguration.fromEnvironment(environment)

        return LLMProviderRuntimeConfiguration(
            defaultProvider: preferences.selectedProvider,
            geminiModel: normalized(preferences.geminiModel) ?? envConfig.geminiModel,
            geminiAPIKey: normalized(geminiAPIKey) ?? envConfig.geminiAPIKey,
            anthropicModel: normalized(preferences.anthropicModel) ?? envConfig.anthropicModel,
            anthropicAPIKey: normalized(anthropicAPIKey) ?? envConfig.anthropicAPIKey,
            anthropicBaseURL: url(from: preferences.anthropicBaseURL) ?? envConfig.anthropicBaseURL,
            anthropicVersion: normalized(preferences.anthropicVersion) ?? envConfig.anthropicVersion,
            openAIModel: normalized(preferences.openAIModel) ?? envConfig.openAIModel,
            openAIAPIKey: normalized(openAIAPIKey) ?? envConfig.openAIAPIKey,
            localModel: normalized(preferences.localModel) ?? envConfig.localModel,
            localBaseURL: url(from: preferences.localBaseURL) ?? envConfig.localBaseURL,
            localAPIKey: normalized(localAPIKey) ?? envConfig.localAPIKey
        )
    }

    private func persistPreferences() {
        do {
            let encoded = try JSONEncoder().encode(preferences)
            userDefaults.set(encoded, forKey: StorageKey.preferences)
            lastSaveErrorMessage = nil
        } catch {
            lastSaveErrorMessage = "Failed to save settings. \(error.localizedDescription)"
        }
    }

    private static func loadPreferences(from userDefaults: UserDefaults) -> ProviderPreferences {
        guard
            let data = userDefaults.data(forKey: StorageKey.preferences),
            let decoded = try? JSONDecoder().decode(ProviderPreferences.self, from: data)
        else {
            return .default
        }

        return decoded
    }

    private func persistSecret(_ value: String, account: String) {
        guard !isLoading else { return }

        do {
            if let normalizedValue = normalized(value) {
                try keychain.setString(normalizedValue, for: account)
            } else {
                try keychain.removeValue(for: account)
            }
            lastSaveErrorMessage = nil
        } catch {
            lastSaveErrorMessage = "Failed to save secure setting. \(error.localizedDescription)"
        }
    }

    private func normalized(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func url(from raw: String?) -> URL? {
        guard let normalized = normalized(raw) else {
            return nil
        }
        return URL(string: normalized)
    }
}

private enum StorageKey {
    static let preferences = "settings.preferences"
}

private enum SecretAccount {
    static let gemini = "gemini.apiKey"
    static let anthropic = "anthropic.apiKey"
    static let openAI = "openai.apiKey"
    static let local = "local.apiKey"
}
