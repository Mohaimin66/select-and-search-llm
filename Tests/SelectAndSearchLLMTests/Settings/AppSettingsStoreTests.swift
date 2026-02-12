import XCTest
@testable import SelectAndSearchLLM

final class AppSettingsStoreTests: XCTestCase {
    @MainActor
    func testRuntimeConfigurationUsesStoredSettings() {
        let userDefaults = makeUserDefaults()
        let keychain = InMemoryKeychain()
        let store = AppSettingsStore(userDefaults: userDefaults, keychain: keychain)

        store.preferences.selectedProvider = .anthropic
        store.preferences.geminiModel = "gemini-custom"
        store.preferences.anthropicModel = "claude-custom"
        store.preferences.anthropicBaseURL = "https://example.anthropic.local"
        store.preferences.anthropicVersion = "2025-01-01"
        store.preferences.openAIModel = "openai-custom"
        store.preferences.localModel = "local-custom"
        store.preferences.localBaseURL = "http://localhost:12345"

        store.geminiAPIKey = "gemini-secret"
        store.anthropicAPIKey = "anthropic-secret"
        store.openAIAPIKey = "openai-secret"
        store.localAPIKey = "local-secret"

        let config = store.runtimeConfiguration(environment: [:])

        XCTAssertEqual(config.defaultProvider, .anthropic)
        XCTAssertEqual(config.geminiModel, "gemini-custom")
        XCTAssertEqual(config.geminiAPIKey, "gemini-secret")
        XCTAssertEqual(config.anthropicModel, "claude-custom")
        XCTAssertEqual(config.anthropicAPIKey, "anthropic-secret")
        XCTAssertEqual(config.anthropicBaseURL, URL(string: "https://example.anthropic.local"))
        XCTAssertEqual(config.anthropicVersion, "2025-01-01")
        XCTAssertEqual(config.openAIModel, "openai-custom")
        XCTAssertEqual(config.openAIAPIKey, "openai-secret")
        XCTAssertEqual(config.localModel, "local-custom")
        XCTAssertEqual(config.localBaseURL, URL(string: "http://localhost:12345"))
        XCTAssertEqual(config.localAPIKey, "local-secret")
    }

    @MainActor
    func testRuntimeConfigurationFallsBackToEnvironmentForMissingAPIKeys() {
        let userDefaults = makeUserDefaults()
        let store = AppSettingsStore(userDefaults: userDefaults, keychain: InMemoryKeychain())

        store.geminiAPIKey = ""
        store.anthropicAPIKey = ""
        store.openAIAPIKey = ""
        store.localAPIKey = ""

        let config = store.runtimeConfiguration(
            environment: [
                "GEMINI_API_KEY": "env-gemini",
                "ANTHROPIC_API_KEY": "env-anthropic",
                "OPENAI_API_KEY": "env-openai",
                "LOCAL_LLM_API_KEY": "env-local"
            ]
        )

        XCTAssertEqual(config.geminiAPIKey, "env-gemini")
        XCTAssertEqual(config.anthropicAPIKey, "env-anthropic")
        XCTAssertEqual(config.openAIAPIKey, "env-openai")
        XCTAssertEqual(config.localAPIKey, "env-local")
    }

    @MainActor
    func testSettingsPersistAcrossStoreInstances() {
        let userDefaults = makeUserDefaults()
        let keychain = InMemoryKeychain()

        do {
            let store = AppSettingsStore(userDefaults: userDefaults, keychain: keychain)
            store.preferences.selectedProvider = .openAI
            store.preferences.openAIModel = "gpt-custom"
            store.preferences.explainShortcut = KeyboardShortcut(key: .r, modifiers: [.control, .option])
            store.openAIAPIKey = "persisted-openai"
        }

        let reloadedStore = AppSettingsStore(userDefaults: userDefaults, keychain: keychain)
        let config = reloadedStore.runtimeConfiguration(environment: [:])

        XCTAssertEqual(reloadedStore.preferences.selectedProvider, .openAI)
        XCTAssertEqual(reloadedStore.preferences.openAIModel, "gpt-custom")
        XCTAssertEqual(reloadedStore.preferences.explainShortcut, KeyboardShortcut(key: .r, modifiers: [.control, .option]))
        XCTAssertEqual(config.openAIAPIKey, "persisted-openai")
    }

    @MainActor
    func testLegacyPreferencesWithoutHotkeysUseDefaults() throws {
        let userDefaults = makeUserDefaults()
        let legacyPreferences: [String: Any] = [
            "selectedProvider": "gemini",
            "geminiModel": "legacy-gemini",
            "anthropicModel": "legacy-anthropic",
            "anthropicBaseURL": "https://api.anthropic.com",
            "anthropicVersion": "2023-06-01",
            "openAIModel": "legacy-openai",
            "localModel": "legacy-local",
            "localBaseURL": "http://localhost:11434"
        ]
        let data = try JSONSerialization.data(withJSONObject: legacyPreferences)
        userDefaults.set(data, forKey: "settings.preferences")

        let store = AppSettingsStore(userDefaults: userDefaults, keychain: InMemoryKeychain())

        XCTAssertEqual(store.preferences.geminiModel, "legacy-gemini")
        XCTAssertEqual(store.preferences.explainShortcut, .defaultExplain)
        XCTAssertEqual(store.preferences.askShortcut, .defaultAsk)
    }

    private func makeUserDefaults() -> UserDefaults {
        let suite = "AppSettingsStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}

private final class InMemoryKeychain: KeychainValueStoring {
    private var values: [String: String] = [:]

    func string(for account: String) -> String? {
        values[account]
    }

    func setString(_ value: String, for account: String) throws {
        values[account] = value
    }

    func removeValue(for account: String) throws {
        values.removeValue(forKey: account)
    }
}
