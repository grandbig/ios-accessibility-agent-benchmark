import SwiftUI

/// identifier / label の付け方の検証画面（Issue #1 の「本命」）。
///
/// 親View/子Button への identifier の付け方や、label/identifier の有無で、
/// XCUITest などの自動操作から要素がどう見えるか（検出できるか・埋もれるか）を比較する。
/// List のセル層による交絡を避けるため、ScrollView + VStack で素直に並べる。
/// 命名規約: `idlabel.caseN.*`
struct IdentifierLabelView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    case1
                    case2
                    case3
                    case4
                    case5
                    case6
                    case7
                }
                .padding()
            }
            .navigationTitle("ID/Label")
        }
    }

    // ① 子Buttonのみに identifier（親は無印）
    private var case1: some View {
        caseContainer("① 子Buttonのみにidentifier") {
            HStack {
                Text("親")
                Button("子ボタン1") {}
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("idlabel.case1.child")
            }
        }
    }

    // ② 親View のみに identifier（子Buttonは無印）
    private var case2: some View {
        caseContainer("② 親Viewのみにidentifier") {
            HStack {
                Text("親")
                Button("子ボタン2") {}
                    .buttonStyle(.bordered)
            }
            .accessibilityIdentifier("idlabel.case2.parent")
        }
    }

    // ③ 親View + 子Button の両方に identifier
    private var case3: some View {
        caseContainer("③ 親View+子Button両方にidentifier") {
            HStack {
                Text("親")
                Button("子ボタン3") {}
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("idlabel.case3.child")
            }
            .accessibilityIdentifier("idlabel.case3.parent")
        }
    }

    // ④ label のみ（identifier なし）
    private var case4: some View {
        caseContainer("④ labelのみ（identifierなし）") {
            Button("子ボタン4") {}
                .buttonStyle(.bordered)
        }
    }

    // ⑤ identifier のみ（アクセシビリティラベルになるテキストなし＝装飾図形）
    //    SF Symbol は自動でラベルを持つ場合があるため、ラベルを持たない Circle を使う。
    private var case5: some View {
        caseContainer("⑤ identifierのみ（ラベルなし・図形）") {
            Button {
            } label: {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("idlabel.case5.noLabelButton")
        }
    }

    // ⑥ label + identifier の両方
    private var case6: some View {
        caseContainer("⑥ label + identifier両方") {
            Button("子ボタン6") {}
                .buttonStyle(.bordered)
                .accessibilityIdentifier("idlabel.case6.button")
        }
    }

    // ⑦ 親View + 子Button 両方に identifier だが、親に accessibilityElement(children: .contain) を付与
    //    Apple Developer Forums で Apple エンジニアが提示した回避策。子の identifier が保持されるはず。
    private var case7: some View {
        caseContainer("⑦ 親に accessibilityElement(children: .contain)") {
            HStack {
                Text("親")
                Button("子ボタン7") {}
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("idlabel.case7.child")
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("idlabel.case7.parent")
        }
    }

    private func caseContainer<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
        }
    }
}

#Preview {
    IdentifierLabelView()
}
