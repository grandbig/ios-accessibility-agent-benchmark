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
            }
            .navigationTitle("About")
        }
    }
}

#Preview {
    AboutView()
}
