import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsStore: AppSettingsStore

    var body: some View {
        Form {
            Section("Default Provider") {
                Picker("Provider", selection: binding(\.selectedProvider)) {
                    ForEach(LLMProviderKind.allCases, id: \.self) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Model Settings") {
                TextField("Gemini model", text: binding(\.geminiModel))
                TextField("Anthropic model", text: binding(\.anthropicModel))
                TextField("Anthropic base URL", text: binding(\.anthropicBaseURL))
                TextField("Anthropic version", text: binding(\.anthropicVersion))
                TextField("OpenAI model", text: binding(\.openAIModel))
                TextField("Local model", text: binding(\.localModel))
                TextField("Local base URL", text: binding(\.localBaseURL))
            }

            Section("API Keys (Stored In Keychain)") {
                SecureField("Gemini API key", text: $settingsStore.geminiAPIKey)
                SecureField("Anthropic API key", text: $settingsStore.anthropicAPIKey)
                SecureField("OpenAI API key", text: $settingsStore.openAIAPIKey)
                SecureField("Local API key (optional)", text: $settingsStore.localAPIKey)
            }

            if let error = settingsStore.lastSaveErrorMessage {
                Section("Save Status") {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
        }
        .frame(minWidth: 560, minHeight: 420)
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<ProviderPreferences, Value>) -> Binding<Value> {
        Binding(
            get: { settingsStore.preferences[keyPath: keyPath] },
            set: { settingsStore.preferences[keyPath: keyPath] = $0 }
        )
    }
}
