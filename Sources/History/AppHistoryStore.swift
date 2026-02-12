import Combine
import Foundation

@MainActor
final class AppHistoryStore: ObservableObject {
    @Published private(set) var entries: [HistoryEntry] = []
    @Published private(set) var lastPersistenceErrorMessage: String?

    private let persistence: any HistoryPersisting
    private let maxEntries: Int
    private let now: () -> Date

    init(
        persistence: any HistoryPersisting = FileHistoryPersistence(),
        maxEntries: Int = 500,
        now: @escaping () -> Date = Date.init
    ) {
        self.persistence = persistence
        self.maxEntries = maxEntries
        self.now = now
        loadEntries()
    }

    func record(_ input: HistoryRecordInput) {
        let entry = HistoryEntry(
            id: UUID(),
            createdAt: now(),
            interactionMode: input.interactionMode,
            source: input.source,
            appName: input.appName,
            provider: input.provider,
            selectionText: input.selectionText,
            prompt: input.prompt,
            responseText: input.responseText
        )

        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        persistEntries()
    }

    func clearAll() {
        entries.removeAll()
        persistEntries()
    }

    func entry(id: UUID?) -> HistoryEntry? {
        guard let id else { return nil }
        return entries.first { $0.id == id }
    }

    private func loadEntries() {
        do {
            let loaded = try persistence.loadEntries()
            entries = loaded.sorted { $0.createdAt > $1.createdAt }
            lastPersistenceErrorMessage = nil
        } catch {
            entries = []
            lastPersistenceErrorMessage = "Failed to load history. \(error.localizedDescription)"
        }
    }

    private func persistEntries() {
        do {
            try persistence.saveEntries(entries)
            lastPersistenceErrorMessage = nil
        } catch {
            lastPersistenceErrorMessage = "Failed to save history. \(error.localizedDescription)"
        }
    }
}
