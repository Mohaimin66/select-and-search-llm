import Foundation

protocol HistoryPersisting: Sendable {
    func loadEntries() throws -> [HistoryEntry]
    func saveEntries(_ entries: [HistoryEntry]) throws
}

struct FileHistoryPersistence: HistoryPersisting, @unchecked Sendable {
    private let fileURL: URL
    private let fileManager: FileManager

    init(fileURL: URL = Self.defaultFileURL(), fileManager: FileManager = .default) {
        self.fileURL = fileURL
        self.fileManager = fileManager
    }

    func loadEntries() throws -> [HistoryEntry] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([HistoryEntry].self, from: data)
    }

    func saveEntries(_ entries: [HistoryEntry]) throws {
        try ensureParentDirectoryExists()
        let data = try JSONEncoder().encode(entries)
        try data.write(to: fileURL, options: .atomic)
    }

    static func defaultFileURL(
        fileManager: FileManager = .default,
        bundleIdentifier: String = Bundle.main.bundleIdentifier ?? "com.mohaimin66.select-and-search-llm"
    ) -> URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let root = appSupport ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        return root
            .appendingPathComponent(bundleIdentifier, isDirectory: true)
            .appendingPathComponent("history.json")
    }

    private func ensureParentDirectoryExists() throws {
        let directory = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }
}
