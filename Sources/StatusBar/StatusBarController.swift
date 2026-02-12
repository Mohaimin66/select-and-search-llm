import AppKit
import Combine

@MainActor
final class StatusBarController: NSObject {
    private(set) var statusItem: NSStatusItem
    private let historyWindowController: HistoryWindowController
    private let settingsWindowController: SettingsWindowController
    private let selectionCaptureService: SelectionCaptureService
    private let selectionPopoverController: SelectionPopoverController
    private let settingsStore: AppSettingsStore
    private var hotkeyService: GlobalHotkeyService?
    private var cancellables = Set<AnyCancellable>()
    private var lastRegisteredShortcuts: (explain: KeyboardShortcut, ask: KeyboardShortcut)?

    init(settingsStore: AppSettingsStore, historyStore: AppHistoryStore) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        historyWindowController = HistoryWindowController(historyStore: historyStore)
        settingsWindowController = SettingsWindowController(settingsStore: settingsStore)
        selectionCaptureService = SelectionCaptureService()
        selectionPopoverController = SelectionPopoverController(historyStore: historyStore)
        self.settingsStore = settingsStore
        super.init()
        configureStatusItem()
        configureGlobalHotkeys()
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
        let configuredResponse = makeConfiguredResponseGenerator()
        selectionPopoverController.present(
            selectionResult: result,
            mode: .explain,
            responseGenerator: configuredResponse.generator,
            providerKind: configuredResponse.providerKind,
            activeAppName: activeAppName()
        )
    }

    @objc private func askSelection() {
        guard let result = captureSelectionOrAlert() else { return }
        let configuredResponse = makeConfiguredResponseGenerator()
        selectionPopoverController.present(
            selectionResult: result,
            mode: .ask,
            responseGenerator: configuredResponse.generator,
            providerKind: configuredResponse.providerKind,
            activeAppName: activeAppName()
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

    private func makeConfiguredResponseGenerator() -> (generator: SelectionResponseGenerating, providerKind: LLMProviderKind) {
        let configuration = settingsStore.runtimeConfiguration()
        return (
            generator: SelectionResponseGeneratorFactory.makeDefault(configuration: configuration),
            providerKind: configuration.defaultProvider
        )
    }

    private func activeAppName() -> String? {
        NSWorkspace.shared.frontmostApplication?.localizedName
    }

    private func configureGlobalHotkeys() {
        hotkeyService = GlobalHotkeyService(
            onExplain: { [weak self] in
                Task { @MainActor in
                    self?.explainSelection()
                }
            },
            onAsk: { [weak self] in
                Task { @MainActor in
                    self?.askSelection()
                }
            }
        )

        updateRegisteredHotkeys(
            explain: settingsStore.preferences.explainShortcut,
            ask: settingsStore.preferences.askShortcut
        )

        settingsStore.$preferences
            .sink { [weak self] preferences in
                self?.updateRegisteredHotkeys(
                    explain: preferences.explainShortcut,
                    ask: preferences.askShortcut
                )
            }
            .store(in: &cancellables)
    }

    private func updateRegisteredHotkeys(
        explain: KeyboardShortcut,
        ask: KeyboardShortcut
    ) {
        guard lastRegisteredShortcuts?.explain != explain || lastRegisteredShortcuts?.ask != ask else {
            return
        }
        hotkeyService?.updateShortcuts(explain: explain, ask: ask)
        lastRegisteredShortcuts = (explain: explain, ask: ask)
    }
}
