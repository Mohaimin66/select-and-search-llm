import AppKit
import SwiftUI

@MainActor
final class SelectionPopoverController {
    private let historyStore: AppHistoryStore
    private var panelController: NSWindowController?

    init(historyStore: AppHistoryStore) {
        self.historyStore = historyStore
    }

    func present(
        selectionResult: SelectionCaptureResult,
        mode: SelectionPopoverMode,
        responseGenerator: SelectionResponseGenerating? = nil,
        providerKind: LLMProviderKind = .gemini,
        activeAppName: String? = nil
    ) {
        dismiss()

        let viewModel = SelectionPopoverViewModel(
            selectionResult: selectionResult,
            mode: mode,
            responseGenerator: responseGenerator ?? SelectionResponseGeneratorFactory.makeDefault(),
            historyStore: historyStore,
            providerKind: providerKind,
            activeAppName: activeAppName
        )

        let view = SelectionPopoverView(viewModel: viewModel) { [weak self] in
            self?.dismiss()
        }
        let hostingView = NSHostingView(rootView: view)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 430, height: 360),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = viewModel.titleText
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.contentView = hostingView
        panel.setFrameOrigin(bestOrigin(for: panel))

        let controller = NSWindowController(window: panel)
        panelController = controller
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func dismiss() {
        panelController?.close()
        panelController = nil
    }

    private func bestOrigin(for panel: NSPanel) -> NSPoint {
        let mouse = NSEvent.mouseLocation
        var origin = NSPoint(x: mouse.x + 12, y: mouse.y - panel.frame.height - 12)

        if let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) {
            let frame = screen.visibleFrame
            origin.x = min(max(origin.x, frame.minX), frame.maxX - panel.frame.width)
            origin.y = min(max(origin.y, frame.minY), frame.maxY - panel.frame.height)
        }

        return origin
    }
}
