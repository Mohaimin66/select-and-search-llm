import XCTest
@testable import SelectAndSearchLLM

final class SelectionTextNormalizerTests: XCTestCase {
    func testNormalizeReturnsNilForNilInput() {
        let normalizer = SelectionTextNormalizer()
        XCTAssertNil(normalizer.normalize(nil))
    }

    func testNormalizeReturnsNilForWhitespaceOnlyInput() {
        let normalizer = SelectionTextNormalizer()
        XCTAssertNil(normalizer.normalize("   \n\t  "))
    }

    func testNormalizeTrimsLeadingAndTrailingWhitespace() {
        let normalizer = SelectionTextNormalizer()
        XCTAssertEqual(normalizer.normalize("  hello world \n"), "hello world")
    }
}
