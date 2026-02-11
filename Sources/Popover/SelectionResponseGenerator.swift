import Foundation

protocol SelectionResponseGenerating {
    func explain(selectionText: String, source: SelectionSource) -> String
    func answer(prompt: String, selectionText: String, source: SelectionSource) -> String
}

struct DebugSelectionResponseGenerator: SelectionResponseGenerating {
    func explain(selectionText: String, source: SelectionSource) -> String {
        let sourceLabel = source == .accessibility ? "Accessibility" : "Clipboard fallback"
        return "Debug explain response (\(sourceLabel)):\n\n\(selectionText)"
    }

    func answer(prompt: String, selectionText: String, source: SelectionSource) -> String {
        let sourceLabel = source == .accessibility ? "Accessibility" : "Clipboard fallback"
        return "Debug answer (\(sourceLabel)) for prompt: \"\(prompt)\"\n\nSelection:\n\(selectionText)"
    }
}
