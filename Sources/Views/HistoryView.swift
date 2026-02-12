import SwiftUI

struct HistoryView: View {
    @ObservedObject var historyStore: AppHistoryStore
    @State private var selectedEntryID: UUID?

    var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: 8) {
                Text("History")
                    .font(.title2)
                    .bold()

                if historyStore.entries.isEmpty {
                    Text("No history yet.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    List(historyStore.entries, selection: $selectedEntryID) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.prompt ?? entry.selectionText)
                                .lineLimit(1)
                            Text("\(entry.interactionMode.displayName) • \(entry.provider.displayName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(entry.id)
                    }
                }
            }
            .frame(minWidth: 280)
            .padding(14)

            VStack(alignment: .leading, spacing: 10) {
                if let entry = historyStore.entry(id: selectedEntryID) {
                    Text(entry.interactionMode.displayName)
                        .font(.title3)
                        .bold()

                    Text(detailSubtitle(for: entry))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let prompt = entry.prompt {
                        labeledText(title: "Prompt", text: prompt)
                    }
                    labeledText(title: "Selection", text: entry.selectionText)
                    labeledText(title: "Response", text: entry.responseText)
                } else {
                    Text("Select an entry to view details.")
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .frame(minWidth: 340)
            .padding(14)
        }
        .frame(minWidth: 700, minHeight: 460)
        .toolbar {
            Button("Clear History") {
                historyStore.clearAll()
                selectedEntryID = nil
            }
            .disabled(historyStore.entries.isEmpty)
        }
        .onAppear {
            syncSelectionWithEntries()
        }
        .onChange(of: historyStore.entries) { _ in
            syncSelectionWithEntries()
        }
    }

    private func detailSubtitle(for entry: HistoryEntry) -> String {
        let timestamp = entry.createdAt.formatted(date: .abbreviated, time: .shortened)
        let appName = entry.appName ?? "Unknown App"
        return "\(timestamp) • \(appName) • \(entry.source.displayLabel)"
    }

    private func syncSelectionWithEntries() {
        guard let selectedEntryID else {
            self.selectedEntryID = historyStore.entries.first?.id
            return
        }
        guard historyStore.entries.contains(where: { $0.id == selectedEntryID }) else {
            self.selectedEntryID = historyStore.entries.first?.id
            return
        }
    }

    @ViewBuilder
    private func labeledText(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .bold()
            ScrollView {
                Text(text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(minHeight: 72, maxHeight: 140)
        }
    }
}
