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
    private var loadingCounter: Int = 0 {
        didSet {
            isLoading = loadingCounter > 0
        }
    }

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
        "Source: \(selectionResult.source.displayLabel)"
    }

    func loadExplainResponseIfNeeded() async {
        guard mode == .explain, !hasLoadedExplainResponse else {
            return
        }

        let didSucceed = await loadResponse {
            try await responseGenerator.explain(
                selectionText: selectionResult.text,
                source: selectionResult.source
            )
        }

        if didSucceed {
            hasLoadedExplainResponse = true
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

    @discardableResult
    private func loadResponse(_ operation: @MainActor () async throws -> String) async -> Bool {
        loadingCounter += 1
        defer {
            loadingCounter = max(loadingCounter - 1, 0)
        }

        do {
            responseText = try await operation()
            return true
        } catch {
            responseText = "Error: \(message(for: error))"
            return false
        }
    }

    private func message(for error: Error) -> String {
        if let localized = error as? LocalizedError, let description = localized.errorDescription {
            return description
        }

        return String(describing: error)
    }
}
