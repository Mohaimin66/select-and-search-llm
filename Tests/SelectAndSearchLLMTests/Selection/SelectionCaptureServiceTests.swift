import XCTest
@testable import SelectAndSearchLLM

final class SelectionCaptureServiceTests: XCTestCase {
    @MainActor
    func testCapturePrefersAccessibilitySelection() {
        let service = SelectionCaptureService(
            accessibilityProvider: StubAccessibilityProvider(text: "  from accessibility  "),
            clipboardProvider: StubClipboardProvider(text: "from clipboard"),
            normalizer: SelectionTextNormalizer()
        )

        let result = service.captureSelection()

        XCTAssertEqual(result?.text, "from accessibility")
        XCTAssertEqual(result?.source, .accessibility)
    }

    @MainActor
    func testCaptureFallsBackToClipboard() {
        let service = SelectionCaptureService(
            accessibilityProvider: StubAccessibilityProvider(text: nil),
            clipboardProvider: StubClipboardProvider(text: "  from clipboard "),
            normalizer: SelectionTextNormalizer()
        )

        let result = service.captureSelection()

        XCTAssertEqual(result?.text, "from clipboard")
        XCTAssertEqual(result?.source, .clipboard)
    }

    @MainActor
    func testCaptureReturnsNilWhenNoProviderHasText() {
        let service = SelectionCaptureService(
            accessibilityProvider: StubAccessibilityProvider(text: "\n  "),
            clipboardProvider: StubClipboardProvider(text: nil),
            normalizer: SelectionTextNormalizer()
        )

        XCTAssertNil(service.captureSelection())
    }
}

@MainActor
private struct StubAccessibilityProvider: AccessibilitySelectionProviding {
    let text: String?

    func selectedText() -> String? {
        text
    }
}

@MainActor
private struct StubClipboardProvider: ClipboardSelectionProviding {
    let text: String?

    func selectedTextByClipboardCopy() -> String? {
        text
    }
}
