import XCTest
@testable import SelectAndSearchLLM

final class AppHistoryStoreTests: XCTestCase {
    @MainActor
    func testRecordAddsEntryAndPersists() async {
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
        XCTAssertEqual(store.entries.first?.createdAt, fixedDate)
        XCTAssertEqual(store.entries.first?.appName, "Safari")
        XCTAssertEqual(store.entries.first?.provider, .gemini)
        await waitUntil { persistence.savedEntriesSnapshot.count == 1 }
    }

    @MainActor
    func testLoadedEntriesAreSortedByNewestFirst() async {
        let older = Date(timeIntervalSince1970: 1_700_000_000)
        let newer = Date(timeIntervalSince1970: 1_750_000_000)
        let persistence = InMemoryHistoryPersistence(
            loadedEntries: [
                makeEntry(createdAt: older, prompt: "old"),
                makeEntry(createdAt: newer, prompt: "new")
            ]
        )

        let store = AppHistoryStore(persistence: persistence)
        await waitUntil { store.entries.count == 2 }

        XCTAssertEqual(store.entries.count, 2)
        XCTAssertEqual(store.entries.first?.prompt, "new")
        XCTAssertEqual(store.entries.last?.prompt, "old")
    }

    @MainActor
    func testClearAllPersistsEmptyEntries() async {
        let persistence = InMemoryHistoryPersistence(loadedEntries: [makeEntry(createdAt: Date(), prompt: "entry")])
        let store = AppHistoryStore(persistence: persistence)
        await waitUntil { store.entries.count == 1 }

        store.clearAll()
        await waitUntil { persistence.saveCallCountSnapshot > 0 }

        XCTAssertTrue(store.entries.isEmpty)
        XCTAssertTrue(persistence.savedEntriesSnapshot.isEmpty)
    }

    @MainActor
    func testMaxEntriesLimitIsApplied() async {
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
        await waitUntil { persistence.savedEntriesSnapshot.count == 2 }
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

    @MainActor
    private func waitUntil(
        timeout: TimeInterval = 1.0,
        condition: @escaping @MainActor () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() {
                return
            }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("Condition not met before timeout")
    }
}

private final class InMemoryHistoryPersistence: HistoryPersisting, @unchecked Sendable {
    private let lock = NSLock()
    private var loadedEntries: [HistoryEntry]
    private var savedEntries: [HistoryEntry] = []
    private var saveCallCount = 0

    init(loadedEntries: [HistoryEntry] = []) {
        self.loadedEntries = loadedEntries
    }

    func loadEntries() throws -> [HistoryEntry] {
        lock.withLock {
            loadedEntries
        }
    }

    func saveEntries(_ entries: [HistoryEntry]) throws {
        lock.withLock {
            savedEntries = entries
            saveCallCount += 1
        }
    }

    var savedEntriesSnapshot: [HistoryEntry] {
        lock.withLock {
            savedEntries
        }
    }

    var saveCallCountSnapshot: Int {
        lock.withLock {
            saveCallCount
        }
    }
}

private extension NSLock {
    func withLock<T>(_ operation: () -> T) -> T {
        lock()
        defer { unlock() }
        return operation()
    }
}
