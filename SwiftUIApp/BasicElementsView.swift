import SwiftUI

/// 基本要素の基準値画面。
///
/// 各 UI 要素は素直な標準 API で実装し、操作対象には命名規約に沿った
/// accessibilityIdentifier を付与する（命名: `<screen>.<element>`）。
/// 「普通に作れば各ツール（Accessibility Inspector / XCUITest / Maestro /
/// agent-device）で検出できる」という土台（基準値）をここで確認する。
struct BasicElementsView: View {
    @State private var textInput = ""
    @State private var secureInput = ""
    @State private var isToggleOn = false
    @State private var showSheet = false
    @State private var showAlert = false
    @State private var tapCount = 0

    private let listItems = ["りんご", "みかん", "ぶどう"]

    var body: some View {
        NavigationStack {
            List {
                textSection
                buttonSection
                inputSection
                listSection
                scrollSection
                modalSection
            }
            .navigationTitle("基本要素")
            .sheet(isPresented: $showSheet) {
                modalContent
            }
            .alert("アラート", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
                    .accessibilityIdentifier("basics.alert.okButton")
            } message: {
                Text("これは標準のアラートです。")
            }
        }
    }

    // MARK: - Sections

    private var textSection: some View {
        Section("テキスト") {
            Text("これは静的なテキストです。")
                .accessibilityIdentifier("basics.staticText")
        }
    }

    private var buttonSection: some View {
        Section("ボタン") {
            Button("タップ回数: \(tapCount)") {
                tapCount += 1
            }
            .accessibilityIdentifier("basics.primaryButton")

            Toggle("トグル", isOn: $isToggleOn)
                .accessibilityIdentifier("basics.toggle")
        }
    }

    private var inputSection: some View {
        Section("入力") {
            TextField("テキストを入力", text: $textInput)
                .accessibilityIdentifier("basics.textField")

            SecureField("パスワードを入力", text: $secureInput)
                .accessibilityIdentifier("basics.secureField")
        }
    }

    private var listSection: some View {
        Section("リスト") {
            ForEach(Array(listItems.enumerated()), id: \.offset) { index, item in
                Text(item)
                    .accessibilityIdentifier("basics.listItem.\(index)")
            }
        }
    }

    private var scrollSection: some View {
        Section("ScrollView内の要素") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<10, id: \.self) { index in
                        Text("\(index)")
                            .font(.headline)
                            .frame(width: 56, height: 56)
                            .background(Color.accentColor.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .accessibilityIdentifier("basics.scrollItem.\(index)")
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var modalSection: some View {
        Section("モーダル / アラート") {
            Button("モーダルを開く") {
                showSheet = true
            }
            .accessibilityIdentifier("basics.showModalButton")

            Button("アラートを表示") {
                showAlert = true
            }
            .accessibilityIdentifier("basics.showAlertButton")
        }
    }

    private var modalContent: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("モーダル")
                    .font(.title2)
                    .accessibilityIdentifier("modal.title")
                Text("これは標準の sheet で表示したモーダルです。")
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("modal.body")
            }
            .padding()
            .navigationTitle("モーダル")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") {
                        showSheet = false
                    }
                    .accessibilityIdentifier("modal.closeButton")
                }
            }
        }
    }
}

#Preview {
    BasicElementsView()
}
