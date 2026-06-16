import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("iOS Accessibility × Agent Benchmark")
                    .font(.headline)
                    .accessibilityIdentifier("about.title")
                Text("基本要素の基準値画面（SwiftUI）")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("about.subtitle")

                Section("実例（リアルな画面）") {
                    NavigationLink("設定画面") {
                        SettingsView()
                    }
                    .accessibilityIdentifier("about.settingsLink")
                }
            }
            .navigationTitle("About")
        }
    }
}

#Preview {
    AboutView()
}
