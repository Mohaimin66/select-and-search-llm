import Foundation

enum HistoryInteractionMode: String, CaseIterable, Codable, Equatable, Sendable {
    case explain
    case ask

    var displayName: String {
        switch self {
        case .explain:
            return "Explain"
        case .ask:
            return "Ask"
        }
    }
}

struct HistoryRecordInput: Equatable, Sendable {
    let interactionMode: HistoryInteractionMode
    let source: SelectionSource
    let appName: String?
    let provider: LLMProviderKind
    let selectionText: String
    let prompt: String?
    let responseText: String
}

struct HistoryEntry: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let createdAt: Date
    let interactionMode: HistoryInteractionMode
    let source: SelectionSource
    let appName: String?
    let provider: LLMProviderKind
    let selectionText: String
    let prompt: String?
    let responseText: String
}
