import XCTest
@testable import SelectAndSearchLLM

final class SelectionPopoverViewModelTests: XCTestCase {
    @MainActor
    func testExplainModeLoadsInitialResponse() async {
        let viewModel = SelectionPopoverViewModel(
            selectionResult: SelectionCaptureResult(text: "sample", source: .accessibility),
            mode: .explain,
            responseGenerator: StubGenerator(),
            normalizer: SelectionTextNormalizer()
        )

        await viewModel.loadExplainResponseIfNeeded()

        XCTAssertEqual(viewModel.titleText, "Explain Selection")
        XCTAssertEqual(viewModel.responseText, "explain:sample")
    }

    @MainActor
    func testAskModeStartsWithoutResponseUntilPromptSubmitted() async {
        let viewModel = SelectionPopoverViewModel(
            selectionResult: SelectionCaptureResult(text: "sample", source: .clipboard),
            mode: .ask,
            responseGenerator: StubGenerator(),
            normalizer: SelectionTextNormalizer()
        )

        XCTAssertEqual(viewModel.titleText, "Ask About Selection")
        XCTAssertEqual(viewModel.responseText, "")

        viewModel.promptText = "  question  "
        await viewModel.submitPrompt()
        XCTAssertEqual(viewModel.responseText, "answer:question:sample")
    }

    @MainActor
    func testAskModeIgnoresEmptyPrompt() async {
        let viewModel = SelectionPopoverViewModel(
            selectionResult: SelectionCaptureResult(text: "sample", source: .clipboard),
            mode: .ask,
            responseGenerator: StubGenerator(),
            normalizer: SelectionTextNormalizer()
        )

        viewModel.promptText = "   "
        await viewModel.submitPrompt()

        XCTAssertEqual(viewModel.responseText, "")
    }

    @MainActor
    func testViewModelSurfacesProviderErrors() async {
        let viewModel = SelectionPopoverViewModel(
            selectionResult: SelectionCaptureResult(text: "sample", source: .clipboard),
            mode: .ask,
            responseGenerator: FailingGenerator(),
            normalizer: SelectionTextNormalizer()
        )

        viewModel.promptText = "question"
        await viewModel.submitPrompt()

        XCTAssertTrue(viewModel.responseText.contains("Error:"))
    }
}

private struct StubGenerator: SelectionResponseGenerating {
    func explain(selectionText: String, source: SelectionSource) async throws -> String {
        "explain:\(selectionText)"
    }

    func answer(prompt: String, selectionText: String, source: SelectionSource) async throws -> String {
        "answer:\(prompt):\(selectionText)"
    }
}

private struct FailingGenerator: SelectionResponseGenerating {
    func explain(selectionText: String, source: SelectionSource) async throws -> String {
        throw LLMProviderError.invalidResponse
    }

    func answer(prompt: String, selectionText: String, source: SelectionSource) async throws -> String {
        throw LLMProviderError.invalidResponse
    }
}
