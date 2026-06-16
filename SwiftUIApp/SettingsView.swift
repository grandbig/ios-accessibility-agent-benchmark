import SwiftUI

/// 実アプリ寄せの「設定」画面。基本要素の合成画面では現れなかった
/// Slider / Stepper / Picker / NavigationLink / 複数 Toggle を、現実的な文脈でまとめて検証する。
/// （About 画面の「実例」から NavigationLink で開く。タブ上限5を超えないため。）
/// 命名規約: `settings.*`
struct SettingsView: View {
    @State private var pushEnabled = true
    @State private var emailEnabled = false
    @State private var theme = "システム"
    @State private var fontSize = 14.0
    @State private var lineSpacing = 2
    @State private var lastAction = "なし"

    private let themes = ["システム", "ライト", "ダーク"]

    var body: some View {
        List {
            Section("通知") {
                Toggle("プッシュ通知", isOn: $pushEnabled)
                    .accessibilityIdentifier("settings.push")
                Toggle("メール通知", isOn: $emailEnabled)
                    .accessibilityIdentifier("settings.email")
            }

            Section("表示") {
                Picker("テーマ", selection: $theme) {
                    ForEach(themes, id: \.self) { Text($0).tag($0) }
                }
                .accessibilityIdentifier("settings.theme")

                VStack(alignment: .leading) {
                    Text("文字サイズ: \(Int(fontSize))")
                        .accessibilityIdentifier("settings.fontSizeLabel")
                    Slider(value: $fontSize, in: 10...24, step: 1) {
                        Text("文字サイズ")
                    }
                    .accessibilityIdentifier("settings.fontSize")
                }

                Stepper("行間: \(lineSpacing)", value: $lineSpacing, in: 0...8)
                    .accessibilityIdentifier("settings.lineSpacing")
            }

            Section("その他") {
                NavigationLink("アカウント") {
                    Text("アカウント詳細")
                        .accessibilityIdentifier("settings.accountDetail")
                }
                .accessibilityIdentifier("settings.account")

                Button("キャッシュを削除", role: .destructive) {
                    lastAction = "clearCache"
                }
                .accessibilityIdentifier("settings.clearCache")

                Text("最後の操作: \(lastAction)")
                    .accessibilityIdentifier("settings.lastAction")
            }
        }
        .navigationTitle("設定")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
