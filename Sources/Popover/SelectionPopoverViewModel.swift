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
    private let historyStore: AppHistoryStore?
    private let providerKind: LLMProviderKind
    private let activeAppName: String?
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
        normalizer: SelectionTextNormalizing = SelectionTextNormalizer(),
        historyStore: AppHistoryStore? = nil,
        providerKind: LLMProviderKind,
        activeAppName: String? = nil
    ) {
        self.selectionResult = selectionResult
        self.mode = mode
        self.responseGenerator = responseGenerator
        self.normalizer = normalizer
        self.historyStore = historyStore
        self.providerKind = providerKind
        self.activeAppName = activeAppName
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

        let responseText = await loadResponse {
            try await responseGenerator.explain(
                selectionText: selectionResult.text,
                source: selectionResult.source
            )
        }

        if let responseText {
            hasLoadedExplainResponse = true
            recordHistory(
                interactionMode: .explain,
                prompt: nil,
                responseText: responseText
            )
        }
    }

    func submitPrompt() async {
        guard let prompt = normalizer.normalize(promptText) else {
            return
        }

        guard let responseText = await loadResponse({
            try await responseGenerator.answer(
                prompt: prompt,
                selectionText: selectionResult.text,
                source: selectionResult.source
            )
        }) else {
            return
        }

        recordHistory(
            interactionMode: .ask,
            prompt: prompt,
            responseText: responseText
        )
    }

    private func loadResponse(_ operation: @MainActor () async throws -> String) async -> String? {
        loadingCounter += 1
        defer {
            loadingCounter = max(loadingCounter - 1, 0)
        }

        do {
            let responseText = try await operation()
            self.responseText = responseText
            return responseText
        } catch {
            responseText = "Error: \(message(for: error))"
            return nil
        }
    }

    private func message(for error: Error) -> String {
        if let localized = error as? LocalizedError, let description = localized.errorDescription {
            return description
        }

        return String(describing: error)
    }

    private func recordHistory(
        interactionMode: HistoryInteractionMode,
        prompt: String?,
        responseText: String
    ) {
        historyStore?.record(
            HistoryRecordInput(
                interactionMode: interactionMode,
                source: selectionResult.source,
                appName: activeAppName,
                provider: providerKind,
                selectionText: selectionResult.text,
                prompt: prompt,
                responseText: responseText
            )
        )
    }
}
