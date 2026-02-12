import SwiftUI

@MainActor
struct SelectionPopoverView: View {
    @ObservedObject var viewModel: SelectionPopoverViewModel
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.titleText)
                .font(.headline)

            Text(viewModel.sourceText)
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Selection")
                    .font(.subheadline)
                    .bold()
                ScrollView {
                    Text(viewModel.selectionResult.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(height: 90)
            }

            if viewModel.mode == .ask {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Prompt")
                        .font(.subheadline)
                        .bold()
                    TextField("Ask a question about the selection", text: $viewModel.promptText)
                    Button("Submit Prompt") {
                        Task {
                            await viewModel.submitPrompt()
                        }
                    }
                    .disabled(
                        viewModel.promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading
                    )
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Response")
                    .font(.subheadline)
                    .bold()
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .controlSize(.small)
                }
                ScrollView {
                    Text(viewModel.responseText.isEmpty ? "No response yet." : viewModel.responseText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(height: 120)
            }

            HStack {
                Spacer()
                Button("Close", action: onClose)
            }
        }
        .padding(14)
        .frame(width: 430)
        .task {
            await viewModel.loadExplainResponseIfNeeded()
        }
    }
}
