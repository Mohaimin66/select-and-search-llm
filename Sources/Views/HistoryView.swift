import SwiftUI

struct HistoryView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .font(.title2)
                .bold()

            Text("Your recent explanations will appear here.")
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 420)
    }
}
