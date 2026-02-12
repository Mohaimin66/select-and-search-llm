import Combine
import Foundation

@MainActor
final class AppHistoryStore: ObservableObject {
    @Published private(set) var entries: [HistoryEntry] = []
    @Published private(set) var lastPersistenceErrorMessage: String?

    private let persistence: any HistoryPersisting
    private let persistenceQueue: DispatchQueue
    private let maxEntries: Int
    private let now: () -> Date
    private var mutationVersion: UInt64 = 0

    init(
        persistence: any HistoryPersisting = FileHistoryPersistence(),
        persistenceQueue: DispatchQueue = DispatchQueue(
            label: "com.mohaimin66.selectandsearch.history.persistence",
            qos: .utility
        ),
        maxEntries: Int = 500,
        now: @escaping () -> Date = Date.init
    ) {
        self.persistence = persistence
        self.persistenceQueue = persistenceQueue
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
        mutationVersion &+= 1
        persistEntries(entries)
    }

    func clearAll() {
        entries.removeAll()
        mutationVersion &+= 1
        persistEntries(entries)
    }

    func entry(id: UUID?) -> HistoryEntry? {
        guard let id else { return nil }
        return entries.first { $0.id == id }
    }

    private func loadEntries() {
        let persistence = self.persistence
        let expectedVersion = mutationVersion
        persistenceQueue.async { [weak self] in
            do {
                let loaded = try persistence.loadEntries()
                let sorted = loaded.sorted { $0.createdAt > $1.createdAt }
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    guard self.mutationVersion == expectedVersion else {
                        return
                    }
                    self.entries = sorted
                    self.lastPersistenceErrorMessage = nil
                }
            } catch {
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    guard self.mutationVersion == expectedVersion else {
                        return
                    }
                    self.entries = []
                    self.lastPersistenceErrorMessage = "Failed to load history. \(error.localizedDescription)"
                }
            }
        }
    }

    private func persistEntries(_ snapshot: [HistoryEntry]) {
        let persistence = self.persistence
        persistenceQueue.async { [weak self] in
            do {
                try persistence.saveEntries(snapshot)
                Task { @MainActor [weak self] in
                    self?.lastPersistenceErrorMessage = nil
                }
            } catch {
                Task { @MainActor [weak self] in
                    self?.lastPersistenceErrorMessage = "Failed to save history. \(error.localizedDescription)"
                }
            }
        }
    }
}
