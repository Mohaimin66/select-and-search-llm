import XCTest
@testable import SelectAndSearchLLM

final class AppShellTests: XCTestCase {
    func testStatusBarMenuModelHasExpectedItems() {
        let items = StatusBarMenuModel.defaultItems

        XCTAssertEqual(items.count, 7)
        XCTAssertEqual(items[safe: 0]?.title, "Explain Selection (Debug)")
        XCTAssertEqual(items[safe: 1]?.title, "Ask About Selection (Debug)")
        XCTAssertEqual(items[safe: 2]?.isSeparator, true)
        XCTAssertEqual(items[safe: 3]?.title, "Open History")
        XCTAssertEqual(items[safe: 4]?.title, "Settings")
        XCTAssertEqual(items[safe: 5]?.isSeparator, true)
        XCTAssertEqual(items[safe: 6]?.title, "Quit")
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
