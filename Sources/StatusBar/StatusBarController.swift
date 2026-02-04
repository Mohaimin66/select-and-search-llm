import AppKit

@MainActor
final class StatusBarController: NSObject {
    private(set) var statusItem: NSStatusItem
    private let historyWindowController: HistoryWindowController
    private let settingsWindowController: SettingsWindowController

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        historyWindowController = HistoryWindowController()
        settingsWindowController = SettingsWindowController()
        super.init()
        configureStatusItem()
    }

    private func configureStatusItem() {
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "text.magnifyingglass",
                accessibilityDescription: "Select-and-Search LLM"
            )
        }

        let menu = NSMenu()
        menu.addItem(makeItem(title: "Open History", action: #selector(openHistory), key: "h"))
        menu.addItem(makeItem(title: "Settings", action: #selector(openSettings), key: ","))
        menu.addItem(.separator())
        menu.addItem(makeItem(title: "Quit", action: #selector(quitApp), key: "q"))
        statusItem.menu = menu
    }

    private func makeItem(title: String, action: Selector, key: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    @objc private func openHistory() {
        historyWindowController.show()
    }

    @objc private func openSettings() {
        settingsWindowController.show()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
