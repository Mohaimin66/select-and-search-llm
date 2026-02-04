import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.title2)
                .bold()

            Text("Provider configuration and hotkeys will appear here.")
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(20)
        .frame(minWidth: 480, minHeight: 360)
    }
}
