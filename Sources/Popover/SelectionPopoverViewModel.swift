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

    private let responseGenerator: SelectionResponseGenerating
    private let normalizer: SelectionTextNormalizing

    init(
        selectionResult: SelectionCaptureResult,
        mode: SelectionPopoverMode,
        responseGenerator: SelectionResponseGenerating = DebugSelectionResponseGenerator(),
        normalizer: SelectionTextNormalizing = SelectionTextNormalizer()
    ) {
        self.selectionResult = selectionResult
        self.mode = mode
        self.responseGenerator = responseGenerator
        self.normalizer = normalizer
        if mode == .explain {
            loadExplainResponse()
        }
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

    func submitPrompt() {
        guard let prompt = normalizer.normalize(promptText) else {
            return
        }

        responseText = responseGenerator.answer(
            prompt: prompt,
            selectionText: selectionResult.text,
            source: selectionResult.source
        )
    }

    private func loadExplainResponse() {
        responseText = responseGenerator.explain(
            selectionText: selectionResult.text,
            source: selectionResult.source
        )
    }
}
