import Foundation

protocol SelectionResponseGenerating {
    func explain(selectionText: String, source: SelectionSource) -> String
    func answer(prompt: String, selectionText: String, source: SelectionSource) -> String
}

struct DebugSelectionResponseGenerator: SelectionResponseGenerating {
    private func sourceLabel(for source: SelectionSource) -> String {
        source == .accessibility ? "Accessibility" : "Clipboard fallback"
    }

    func explain(selectionText: String, source: SelectionSource) -> String {
        let sourceLabel = sourceLabel(for: source)
        return "Debug explain response (\(sourceLabel)):\n\n\(selectionText)"
    }

    func answer(prompt: String, selectionText: String, source: SelectionSource) -> String {
        let sourceLabel = sourceLabel(for: source)
        return "Debug answer (\(sourceLabel)) for prompt: \"\(prompt)\"\n\nSelection:\n\(selectionText)"
    }
}
