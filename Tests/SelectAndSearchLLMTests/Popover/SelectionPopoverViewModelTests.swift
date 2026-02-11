import XCTest
@testable import SelectAndSearchLLM

final class SelectionPopoverViewModelTests: XCTestCase {
    @MainActor
    func testExplainModeLoadsInitialResponse() {
        let viewModel = SelectionPopoverViewModel(
            selectionResult: SelectionCaptureResult(text: "sample", source: .accessibility),
            mode: .explain,
            responseGenerator: StubGenerator(),
            normalizer: SelectionTextNormalizer()
        )

        XCTAssertEqual(viewModel.titleText, "Explain Selection")
        XCTAssertEqual(viewModel.responseText, "explain:sample")
    }

    @MainActor
    func testAskModeStartsWithoutResponseUntilPromptSubmitted() {
        let viewModel = SelectionPopoverViewModel(
            selectionResult: SelectionCaptureResult(text: "sample", source: .clipboard),
            mode: .ask,
            responseGenerator: StubGenerator(),
            normalizer: SelectionTextNormalizer()
        )

        XCTAssertEqual(viewModel.titleText, "Ask About Selection")
        XCTAssertEqual(viewModel.responseText, "")

        viewModel.promptText = "  question  "
        viewModel.submitPrompt()
        XCTAssertEqual(viewModel.responseText, "answer:question:sample")
    }

    @MainActor
    func testAskModeIgnoresEmptyPrompt() {
        let viewModel = SelectionPopoverViewModel(
            selectionResult: SelectionCaptureResult(text: "sample", source: .clipboard),
            mode: .ask,
            responseGenerator: StubGenerator(),
            normalizer: SelectionTextNormalizer()
        )

        viewModel.promptText = "   "
        viewModel.submitPrompt()

        XCTAssertEqual(viewModel.responseText, "")
    }
}

private struct StubGenerator: SelectionResponseGenerating {
    func explain(selectionText: String, source: SelectionSource) -> String {
        "explain:\(selectionText)"
    }

    func answer(prompt: String, selectionText: String, source: SelectionSource) -> String {
        "answer:\(prompt):\(selectionText)"
    }
}
