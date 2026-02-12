import Foundation

enum SelectionPopoverMode: Equatable {
    case explain
    case ask
}

@MainActor
final class SelectionPopoverViewModel: ObservableObject {
    let selectionResult: SelectionCaptureResult
    let mode: SelectionPopoverMode

    @Published var promptText: String = ""
    @Published private(set) var responseText: String = ""
    @Published private(set) var isLoading: Bool = false

    private let responseGenerator: SelectionResponseGenerating
    private let normalizer: SelectionTextNormalizing
    private var hasLoadedExplainResponse = false

    init(
        selectionResult: SelectionCaptureResult,
        mode: SelectionPopoverMode,
        responseGenerator: SelectionResponseGenerating = SelectionResponseGeneratorFactory.makeDefault(),
        normalizer: SelectionTextNormalizing = SelectionTextNormalizer()
    ) {
        self.selectionResult = selectionResult
        self.mode = mode
        self.responseGenerator = responseGenerator
        self.normalizer = normalizer
    }

    var titleText: String {
        switch mode {
        case .explain:
            return "Explain Selection"
        case .ask:
            return "Ask About Selection"
        }
    }

    var sourceText: String {
        switch selectionResult.source {
        case .accessibility:
            return "Source: Accessibility"
        case .clipboard:
            return "Source: Clipboard fallback"
        }
    }

    func loadExplainResponseIfNeeded() async {
        guard mode == .explain, !hasLoadedExplainResponse else {
            return
        }

        hasLoadedExplainResponse = true
        await loadResponse {
            try await responseGenerator.explain(
                selectionText: selectionResult.text,
                source: selectionResult.source
            )
        }
    }

    func submitPrompt() async {
        guard let prompt = normalizer.normalize(promptText) else {
            return
        }

        await loadResponse {
            try await responseGenerator.answer(
                prompt: prompt,
                selectionText: selectionResult.text,
                source: selectionResult.source
            )
        }
    }

    private func loadResponse(_ operation: @MainActor () async throws -> String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            responseText = try await operation()
        } catch {
            responseText = "Error: \(message(for: error))"
        }
    }

    private func message(for error: Error) -> String {
        if let localized = error as? LocalizedError, let description = localized.errorDescription {
            return description
        }

        return String(describing: error)
    }
}
