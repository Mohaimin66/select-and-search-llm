import XCTest
@testable import SelectAndSearchLLM

final class SelectionResponseGeneratorTests: XCTestCase {
    func testExplainIncludesSourceAndSelectionText() {
        let generator = DebugSelectionResponseGenerator()
        let response = generator.explain(selectionText: "alpha", source: .accessibility)
        XCTAssertTrue(response.contains("Accessibility"))
        XCTAssertTrue(response.contains("alpha"))
    }

    func testAnswerIncludesPromptAndSelectionText() {
        let generator = DebugSelectionResponseGenerator()
        let response = generator.answer(prompt: "what?", selectionText: "beta", source: .clipboard)
        XCTAssertTrue(response.contains("what?"))
        XCTAssertTrue(response.contains("beta"))
        XCTAssertTrue(response.contains("Clipboard fallback"))
    }
}
