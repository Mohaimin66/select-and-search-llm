import XCTest
@testable import SelectAndSearchLLM

final class KeyboardShortcutTests: XCTestCase {
    func testDisplayLabelIncludesModifiersInStableOrder() {
        let shortcut = KeyboardShortcut(key: .p, modifiers: [.command, .control, .shift])
        XCTAssertEqual(shortcut.displayLabel, "Ctrl + Cmd + Shift + P")
    }

    func testCodableRoundTrip() throws {
        let shortcut = KeyboardShortcut(key: .e, modifiers: [.control, .option])
        let data = try JSONEncoder().encode(shortcut)
        let decoded = try JSONDecoder().decode(KeyboardShortcut.self, from: data)
        XCTAssertEqual(decoded, shortcut)
    }
}
