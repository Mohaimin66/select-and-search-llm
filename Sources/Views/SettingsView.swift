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

            Section("Global Hotkeys") {
                KeyboardShortcutEditor(
                    title: "Explain Selection",
                    shortcut: binding(\.explainShortcut)
                )
                KeyboardShortcutEditor(
                    title: "Ask About Selection",
                    shortcut: binding(\.askShortcut)
                )

                if settingsStore.preferences.explainShortcut == settingsStore.preferences.askShortcut {
                    Text("Explain and Ask use the same shortcut. Use different shortcuts to avoid conflicts.")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
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

private struct KeyboardShortcutEditor: View {
    let title: String
    @Binding var shortcut: KeyboardShortcut

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .bold()

            HStack {
                Picker("Key", selection: $shortcut.key) {
                    ForEach(ShortcutKey.allCases, id: \.self) { key in
                        Text(key.displayName).tag(key)
                    }
                }
                .frame(maxWidth: 120)

                modifierToggle("Ctrl", modifier: .control)
                modifierToggle("Opt", modifier: .option)
                modifierToggle("Cmd", modifier: .command)
                modifierToggle("Shift", modifier: .shift)
            }

            Text("Current: \(shortcut.displayLabel)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func modifierToggle(_ title: String, modifier: ShortcutModifiers) -> some View {
        Toggle(
            title,
            isOn: Binding(
                get: { shortcut.modifiers.contains(modifier) },
                set: { isOn in
                    if isOn {
                        shortcut.modifiers.insert(modifier)
                    } else {
                        shortcut.modifiers.remove(modifier)
                    }
                }
            )
        )
        .toggleStyle(.checkbox)
    }
}
