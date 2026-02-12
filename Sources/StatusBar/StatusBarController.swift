import AppKit

@MainActor
final class StatusBarController: NSObject {
    private(set) var statusItem: NSStatusItem
    private let historyWindowController: HistoryWindowController
    private let settingsWindowController: SettingsWindowController
    private let selectionCaptureService: SelectionCaptureService
    private let selectionPopoverController: SelectionPopoverController
    private let settingsStore: AppSettingsStore

    init(settingsStore: AppSettingsStore) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        historyWindowController = HistoryWindowController()
        settingsWindowController = SettingsWindowController(settingsStore: settingsStore)
        selectionCaptureService = SelectionCaptureService()
        selectionPopoverController = SelectionPopoverController()
        self.settingsStore = settingsStore
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
        for item in StatusBarMenuModel.defaultItems {
            if item.isSeparator {
                menu.addItem(.separator())
                continue
            }

            let menuItem = NSMenuItem(
                title: item.title,
                action: selector(for: item.action),
                keyEquivalent: item.keyEquivalent
            )
            menuItem.target = self
            menu.addItem(menuItem)
        }
        statusItem.menu = menu
    }

    private func selector(for action: StatusBarAction?) -> Selector? {
        guard let action else { return nil }
        switch action {
        case .explainSelection:
            return #selector(explainSelection)
        case .askSelection:
            return #selector(askSelection)
        case .openHistory:
            return #selector(openHistory)
        case .openSettings:
            return #selector(openSettings)
        case .quit:
            return #selector(quitApp)
        }
    }

    @objc private func explainSelection() {
        guard let result = captureSelectionOrAlert() else { return }
        selectionPopoverController.present(
            selectionResult: result,
            mode: .explain,
            responseGenerator: makeResponseGenerator()
        )
    }

    @objc private func askSelection() {
        guard let result = captureSelectionOrAlert() else { return }
        selectionPopoverController.present(
            selectionResult: result,
            mode: .ask,
            responseGenerator: makeResponseGenerator()
        )
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

    private func presentCaptureAlert(title: String, body: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = body
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .informational
        alert.runModal()
    }

    private func captureSelectionOrAlert() -> SelectionCaptureResult? {
        guard let result = selectionCaptureService.captureSelection() else {
            presentCaptureAlert(
                title: "No Selection Captured",
                body: "Select text in another app and try again."
            )
            return nil
        }
        return result
    }

    private func makeResponseGenerator() -> SelectionResponseGenerating {
        let configuration = settingsStore.runtimeConfiguration()
        return SelectionResponseGeneratorFactory.makeDefault(configuration: configuration)
    }
}
