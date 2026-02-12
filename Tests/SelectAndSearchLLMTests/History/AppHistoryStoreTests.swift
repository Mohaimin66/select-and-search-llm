import XCTest
@testable import SelectAndSearchLLM

final class AppHistoryStoreTests: XCTestCase {
    @MainActor
    func testRecordAddsEntryAndPersists() {
        let persistence = InMemoryHistoryPersistence()
        let fixedDate = Date(timeIntervalSince1970: 1_733_000_000)
        let store = AppHistoryStore(persistence: persistence, now: { fixedDate })

        store.record(
            HistoryRecordInput(
                interactionMode: .ask,
                source: .clipboard,
                appName: "Safari",
                provider: .gemini,
                selectionText: "selected text",
                prompt: "what does this mean?",
                responseText: "response"
            )
        )

        XCTAssertEqual(store.entries.count, 1)
        XCTAssertEqual(persistence.savedEntries.count, 1)
        XCTAssertEqual(store.entries.first?.createdAt, fixedDate)
        XCTAssertEqual(store.entries.first?.appName, "Safari")
        XCTAssertEqual(store.entries.first?.provider, .gemini)
    }

    @MainActor
    func testLoadedEntriesAreSortedByNewestFirst() {
        let older = Date(timeIntervalSince1970: 1_700_000_000)
        let newer = Date(timeIntervalSince1970: 1_750_000_000)
        let persistence = InMemoryHistoryPersistence(
            loadedEntries: [
                makeEntry(createdAt: older, prompt: "old"),
                makeEntry(createdAt: newer, prompt: "new")
            ]
        )

        let store = AppHistoryStore(persistence: persistence)

        XCTAssertEqual(store.entries.count, 2)
        XCTAssertEqual(store.entries.first?.prompt, "new")
        XCTAssertEqual(store.entries.last?.prompt, "old")
    }

    @MainActor
    func testClearAllPersistsEmptyEntries() {
        let persistence = InMemoryHistoryPersistence(loadedEntries: [makeEntry(createdAt: Date(), prompt: "entry")])
        let store = AppHistoryStore(persistence: persistence)

        store.clearAll()

        XCTAssertTrue(store.entries.isEmpty)
        XCTAssertTrue(persistence.savedEntries.isEmpty)
    }

    @MainActor
    func testMaxEntriesLimitIsApplied() {
        let persistence = InMemoryHistoryPersistence()
        var tick: TimeInterval = 1_700_000_000
        let store = AppHistoryStore(
            persistence: persistence,
            maxEntries: 2,
            now: {
                defer { tick += 10 }
                return Date(timeIntervalSince1970: tick)
            }
        )

        store.record(makeInput(prompt: "first"))
        store.record(makeInput(prompt: "second"))
        store.record(makeInput(prompt: "third"))

        XCTAssertEqual(store.entries.count, 2)
        XCTAssertEqual(store.entries.map(\.prompt), ["third", "second"])
    }

    private func makeInput(prompt: String) -> HistoryRecordInput {
        HistoryRecordInput(
            interactionMode: .ask,
            source: .accessibility,
            appName: "Chrome",
            provider: .openAI,
            selectionText: "selection",
            prompt: prompt,
            responseText: "response-\(prompt)"
        )
    }

    private func makeEntry(createdAt: Date, prompt: String) -> HistoryEntry {
        HistoryEntry(
            id: UUID(),
            createdAt: createdAt,
            interactionMode: .ask,
            source: .accessibility,
            appName: "Safari",
            provider: .gemini,
            selectionText: "selection",
            prompt: prompt,
            responseText: "response"
        )
    }
}

private final class InMemoryHistoryPersistence: HistoryPersisting {
    var loadedEntries: [HistoryEntry]
    var savedEntries: [HistoryEntry] = []

    init(loadedEntries: [HistoryEntry] = []) {
        self.loadedEntries = loadedEntries
    }

    func loadEntries() throws -> [HistoryEntry] {
        loadedEntries
    }

    func saveEntries(_ entries: [HistoryEntry]) throws {
        savedEntries = entries
    }
}
