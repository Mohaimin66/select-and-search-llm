import XCTest
@testable import SelectAndSearchLLM

@MainActor
final class SelectionResponseGeneratorTests: XCTestCase {
    func testExplainIncludesSourceAndSelectionText() async throws {
        let generator = DebugSelectionResponseGenerator()
        let response = try await generator.explain(selectionText: "alpha", source: .accessibility)
        XCTAssertTrue(response.contains("Accessibility"))
        XCTAssertTrue(response.contains("alpha"))
    }

    func testAnswerIncludesPromptAndSelectionText() async throws {
        let generator = DebugSelectionResponseGenerator()
        let response = try await generator.answer(prompt: "what?", selectionText: "beta", source: .clipboard)
        XCTAssertTrue(response.contains("what?"))
        XCTAssertTrue(response.contains("beta"))
        XCTAssertTrue(response.contains("Clipboard fallback"))
    }

    func testLLMBackedGeneratorBuildsExplainPromptFromSelection() async throws {
        let provider = StubLLMProvider(result: "ok")
        let generator = LLMBackedSelectionResponseGenerator(provider: provider)

        _ = try await generator.explain(selectionText: "Selected sentence", source: .clipboard)

        let capturedInput = await provider.latestInput()
        let input = try XCTUnwrap(capturedInput)
        XCTAssertTrue(input.userPrompt.contains("Selected sentence"))
        XCTAssertTrue(input.userPrompt.contains("Clipboard fallback"))
        XCTAssertNotNil(input.systemPrompt)
    }

    func testLLMBackedGeneratorBuildsAskPromptFromSelectionAndQuestion() async throws {
        let provider = StubLLMProvider(result: "ok")
        let generator = LLMBackedSelectionResponseGenerator(provider: provider)

        _ = try await generator.answer(prompt: "What does it mean?", selectionText: "theta", source: .accessibility)

        let capturedInput = await provider.latestInput()
        let input = try XCTUnwrap(capturedInput)
        XCTAssertTrue(input.userPrompt.contains("theta"))
        XCTAssertTrue(input.userPrompt.contains("What does it mean?"))
        XCTAssertTrue(input.userPrompt.contains("Accessibility"))
    }
}

private actor StubLLMProvider: LLMProvider {
    let kind: LLMProviderKind = .local
    private let result: String
    private var capturedInput: LLMProviderInput?

    init(result: String) {
        self.result = result
    }

    func generateText(input: LLMProviderInput) async throws -> String {
        capturedInput = input
        return result
    }

    func latestInput() -> LLMProviderInput? {
        capturedInput
    }
}
