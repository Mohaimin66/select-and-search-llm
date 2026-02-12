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

    @MainActor
    func testExplainModeRetriesAfterFailure() async {
        let generator = FlakyExplainGenerator()
        let viewModel = SelectionPopoverViewModel(
            selectionResult: SelectionCaptureResult(text: "sample", source: .accessibility),
            mode: .explain,
            responseGenerator: generator,
            normalizer: SelectionTextNormalizer()
        )

        await viewModel.loadExplainResponseIfNeeded()
        XCTAssertTrue(viewModel.responseText.hasPrefix("Error:"))

        await viewModel.loadExplainResponseIfNeeded()
        XCTAssertEqual(viewModel.responseText, "explain:sample")
    }

    @MainActor
    func testIsLoadingTracksConcurrentRequests() async throws {
        let viewModel = SelectionPopoverViewModel(
            selectionResult: SelectionCaptureResult(text: "sample", source: .clipboard),
            mode: .ask,
            responseGenerator: SequencedDelayGenerator(),
            normalizer: SelectionTextNormalizer()
        )

        viewModel.promptText = "question"
        let firstTask = Task { await viewModel.submitPrompt() }
        let secondTask = Task { await viewModel.submitPrompt() }

        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertTrue(viewModel.isLoading)

        try await Task.sleep(nanoseconds: 120_000_000)
        XCTAssertTrue(viewModel.isLoading)

        await firstTask.value
        await secondTask.value
        XCTAssertFalse(viewModel.isLoading)
    }

    @MainActor
    func testSuccessfulAskPersistsHistoryEntry() async {
        let historyStore = AppHistoryStore(persistence: InMemoryHistoryPersistenceForPopover())
        let viewModel = SelectionPopoverViewModel(
            selectionResult: SelectionCaptureResult(text: "sample", source: .accessibility),
            mode: .ask,
            responseGenerator: StubGenerator(),
            normalizer: SelectionTextNormalizer(),
            historyStore: historyStore,
            providerKind: .anthropic,
            activeAppName: "Safari"
        )

        viewModel.promptText = "question"
        await viewModel.submitPrompt()

        XCTAssertEqual(historyStore.entries.count, 1)
        XCTAssertEqual(historyStore.entries.first?.prompt, "question")
        XCTAssertEqual(historyStore.entries.first?.provider, .anthropic)
        XCTAssertEqual(historyStore.entries.first?.appName, "Safari")
    }

    @MainActor
    func testFailedAskDoesNotPersistHistoryEntry() async {
        let historyStore = AppHistoryStore(persistence: InMemoryHistoryPersistenceForPopover())
        let viewModel = SelectionPopoverViewModel(
            selectionResult: SelectionCaptureResult(text: "sample", source: .accessibility),
            mode: .ask,
            responseGenerator: FailingGenerator(),
            normalizer: SelectionTextNormalizer(),
            historyStore: historyStore,
            providerKind: .gemini,
            activeAppName: "Safari"
        )

        viewModel.promptText = "question"
        await viewModel.submitPrompt()

        XCTAssertTrue(historyStore.entries.isEmpty)
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

private actor FlakyExplainState {
    private var shouldFail = true

    func nextShouldFail() -> Bool {
        defer { shouldFail = false }
        return shouldFail
    }
}

private struct FlakyExplainGenerator: SelectionResponseGenerating {
    private let state = FlakyExplainState()

    func explain(selectionText: String, source: SelectionSource) async throws -> String {
        if await state.nextShouldFail() {
            throw LLMProviderError.invalidResponse
        }
        return "explain:\(selectionText)"
    }

    func answer(prompt: String, selectionText: String, source: SelectionSource) async throws -> String {
        "answer:\(prompt):\(selectionText)"
    }
}

private actor DelaySequencer {
    private var callCount = 0

    func nextDelay() -> UInt64 {
        callCount += 1
        return callCount == 1 ? 100_000_000 : 400_000_000
    }
}

private struct SequencedDelayGenerator: SelectionResponseGenerating {
    private let delaySequencer = DelaySequencer()

    func explain(selectionText: String, source: SelectionSource) async throws -> String {
        "explain:\(selectionText)"
    }

    func answer(prompt: String, selectionText: String, source: SelectionSource) async throws -> String {
        let delay = await delaySequencer.nextDelay()
        try await Task.sleep(nanoseconds: delay)
        return "answer:\(prompt):\(selectionText)"
    }
}

private final class InMemoryHistoryPersistenceForPopover: HistoryPersisting {
    func loadEntries() throws -> [HistoryEntry] { [] }
    func saveEntries(_ entries: [HistoryEntry]) throws {}
}
