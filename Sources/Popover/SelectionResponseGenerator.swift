import Foundation

protocol SelectionResponseGenerating: Sendable {
    func explain(selectionText: String, source: SelectionSource) async throws -> String
    func answer(prompt: String, selectionText: String, source: SelectionSource) async throws -> String
}

struct DebugSelectionResponseGenerator: SelectionResponseGenerating {
    private func sourceLabel(for source: SelectionSource) -> String {
        source == .accessibility ? "Accessibility" : "Clipboard fallback"
    }

    func explain(selectionText: String, source: SelectionSource) async throws -> String {
        let sourceLabel = sourceLabel(for: source)
        return "Debug explain response (\(sourceLabel)):\n\n\(selectionText)"
    }

    func answer(prompt: String, selectionText: String, source: SelectionSource) async throws -> String {
        let sourceLabel = sourceLabel(for: source)
        return "Debug answer (\(sourceLabel)) for prompt: \"\(prompt)\"\n\nSelection:\n\(selectionText)"
    }
}

struct LLMBackedSelectionResponseGenerator: SelectionResponseGenerating {
    private let provider: any LLMProvider

    init(provider: any LLMProvider) {
        self.provider = provider
    }

    func explain(selectionText: String, source: SelectionSource) async throws -> String {
        let systemPrompt = "You explain selected text in plain language. Stay concise and accurate."
        let userPrompt = """
        Explain this selected text.
        Source: \(sourceLabel(for: source))

        Selected text:
        \(selectionText)
        """

        return try await provider.generateText(
            input: LLMProviderInput(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt,
                maxOutputTokens: 320,
                temperature: 0.2
            )
        )
    }

    func answer(prompt: String, selectionText: String, source: SelectionSource) async throws -> String {
        let systemPrompt = "Answer questions about selected text. Use only the provided text and be explicit when uncertain."
        let userPrompt = """
        Selected text source: \(sourceLabel(for: source))

        Selected text:
        \(selectionText)

        User question:
        \(prompt)
        """

        return try await provider.generateText(
            input: LLMProviderInput(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt,
                maxOutputTokens: 420,
                temperature: 0.3
            )
        )
    }

    private func sourceLabel(for source: SelectionSource) -> String {
        source == .accessibility ? "Accessibility" : "Clipboard fallback"
    }
}

enum SelectionResponseGeneratorFactory {
    static func makeDefault(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        httpClient: any HTTPClient = URLSessionHTTPClient()
    ) -> SelectionResponseGenerating {
        let config = LLMProviderRuntimeConfiguration.fromEnvironment(environment)
        let provider = LLMProviderFactory.makeProvider(configuration: config, httpClient: httpClient)
        return LLMBackedSelectionResponseGenerator(provider: provider)
    }
}
