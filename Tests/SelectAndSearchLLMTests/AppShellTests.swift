import XCTest
@testable import SelectAndSearchLLM

final class AppShellTests: XCTestCase {
    func testStatusBarMenuModelHasExpectedItems() {
        let items = StatusBarMenuModel.defaultItems

        XCTAssertEqual(items.count, 6)
        XCTAssertEqual(items[safe: 0]?.title, "Capture Selection (Debug)")
        XCTAssertEqual(items[safe: 1]?.isSeparator, true)
        XCTAssertEqual(items[safe: 2]?.title, "Open History")
        XCTAssertEqual(items[safe: 3]?.title, "Settings")
        XCTAssertEqual(items[safe: 4]?.isSeparator, true)
        XCTAssertEqual(items[safe: 5]?.title, "Quit")
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
