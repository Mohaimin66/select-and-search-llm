import Foundation

protocol SelectionResponseGenerating: Sendable {
    func explain(selectionText: String, source: SelectionSource) async throws -> String
    func answer(prompt: String, selectionText: String, source: SelectionSource) async throws -> String
}

struct DebugSelectionResponseGenerator: SelectionResponseGenerating {
    func explain(selectionText: String, source: SelectionSource) async throws -> String {
        let sourceLabel = source.displayLabel
        return "Debug explain response (\(sourceLabel)):\n\n\(selectionText)"
    }

    func answer(prompt: String, selectionText: String, source: SelectionSource) async throws -> String {
        let sourceLabel = source.displayLabel
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
        Source: \(source.displayLabel)

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
        Selected text source: \(source.displayLabel)

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
}

enum SelectionResponseGeneratorFactory {
    static func makeDefault(
        configuration: LLMProviderRuntimeConfiguration,
        httpClient: any HTTPClient = URLSessionHTTPClient()
    ) -> SelectionResponseGenerating {
        let provider = LLMProviderFactory.makeProvider(configuration: configuration, httpClient: httpClient)
        return LLMBackedSelectionResponseGenerator(provider: provider)
    }

    static func makeDefault(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        httpClient: any HTTPClient = URLSessionHTTPClient()
    ) -> SelectionResponseGenerating {
        let config = LLMProviderRuntimeConfiguration.fromEnvironment(environment)
        return makeDefault(configuration: config, httpClient: httpClient)
    }
}
