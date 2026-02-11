import AppKit

@MainActor
protocol ClipboardSelectionProviding {
    func selectedTextByClipboardCopy() -> String?
}

@MainActor
final class ClipboardSelectionProvider: ClipboardSelectionProviding {
    func selectedTextByClipboardCopy() -> String? {
        let pasteboard = NSPasteboard.general
        let snapshot = PasteboardSnapshot(pasteboard: pasteboard)
        let baselineChangeCount = pasteboard.changeCount

        guard triggerCopyShortcut() else {
            return nil
        }

        _ = waitForPasteboardChange(
            pasteboard: pasteboard,
            baselineChangeCount: baselineChangeCount,
            timeout: 0.35
        )

        let captured = pasteboard.string(forType: .string)
        snapshot.restore(into: pasteboard)
        return captured
    }

    private func triggerCopyShortcut() -> Bool {
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            return false
        }

        guard
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: false)
        else {
            return false
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return true
    }

    private func waitForPasteboardChange(
        pasteboard: NSPasteboard,
        baselineChangeCount: Int,
        timeout: TimeInterval
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if pasteboard.changeCount != baselineChangeCount {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }
        return false
    }
}

private struct PasteboardSnapshot {
    private let items: [PasteboardItemSnapshot]

    init(pasteboard: NSPasteboard) {
        self.items = (pasteboard.pasteboardItems ?? []).map(PasteboardItemSnapshot.init)
    }

    func restore(into pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        guard !items.isEmpty else {
            return
        }

        let restoredItems = items.map { $0.makePasteboardItem() }
        pasteboard.writeObjects(restoredItems)
    }
}

private struct PasteboardItemSnapshot {
    let payloads: [(type: NSPasteboard.PasteboardType, data: Data)]

    init(item: NSPasteboardItem) {
        payloads = item.types.compactMap { type in
            guard let data = item.data(forType: type) else {
                return nil
            }
            return (type, data)
        }
    }

    func makePasteboardItem() -> NSPasteboardItem {
        let item = NSPasteboardItem()
        for payload in payloads {
            item.setData(payload.data, forType: payload.type)
        }
        return item
    }
}
