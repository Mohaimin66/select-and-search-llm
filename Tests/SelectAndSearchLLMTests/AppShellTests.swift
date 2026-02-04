import XCTest
@testable import SelectAndSearchLLM

final class AppShellTests: XCTestCase {
    @MainActor
    func testStatusBarMenuHasExpectedItems() {
        let controller = StatusBarController()
        let items = controller.statusItem.menu?.items ?? []

        XCTAssertEqual(items.count, 4)
        XCTAssertEqual(items[safe: 0]?.title, "Open History")
        XCTAssertEqual(items[safe: 1]?.title, "Settings")
        XCTAssertEqual(items[safe: 2]?.isSeparatorItem, true)
        XCTAssertEqual(items[safe: 3]?.title, "Quit")
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
