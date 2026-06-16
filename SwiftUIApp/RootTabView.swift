import SwiftUI

/// アプリのルート。Tab は「基本要素」のひとつなので TabView で実装する。
///
/// メモ: SwiftUI ではタブの内容ビューに付けた accessibilityIdentifier は
/// タブバー側のボタンには伝播しない。タブボタンは主にラベル文字列で識別される。
/// この挙動自体がベンチマークの観察対象になりうる。
struct RootTabView: View {
    var body: some View {
        TabView {
            BasicElementsView()
                .tabItem {
                    Label("基本要素", systemImage: "square.grid.2x2")
                }

            IdentifierLabelView()
                .tabItem {
                    Label("ID/Label", systemImage: "tag")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
    }
}

#Preview {
    RootTabView()
}
