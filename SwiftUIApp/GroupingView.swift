import SwiftUI

/// grouping（`accessibilityElement(children:)`）の検証画面。
///
/// 同じ「タイトル＋サブタイトル＋操作ボタン」のカードに、grouping なし /
/// `.combine` / `.contain` / `.ignore` を適用し、VoiceOver 向けのまとまりと、
/// 自動操作（XCUITest など）からの個別要素の検出性がどうトレードオフするかを比較する。
/// 命名規約: タイトル/サブタイトル/操作 のラベルと `group.<tag>.button` 等の identifier。
struct GroupingView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    caseDefault
                    caseCombine
                    caseContain
                    caseIgnore
                }
                .padding()
            }
            .navigationTitle("Grouping")
        }
    }

    // ① grouping なし（default）：子は個別に公開される
    private var caseDefault: some View {
        section("① groupingなし（default）") {
            card("A")
        }
    }

    // ② .combine：子孫が1つの要素にまとめられ、ラベルが連結される
    private var caseCombine: some View {
        section("② .combine") {
            card("B")
                .accessibilityElement(children: .combine)
        }
    }

    // ③ .contain：コンテナ化するが、子は個別にアクセス可能なまま
    private var caseContain: some View {
        section("③ .contain") {
            card("C")
                .accessibilityElement(children: .contain)
        }
    }

    // ④ .ignore：子を隠し、コンテナの独自ラベルだけにする
    private var caseIgnore: some View {
        section("④ .ignore（+ 独自ラベル）") {
            card("D")
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("グループDのまとめ")
        }
    }

    // カード本体（タイトル・サブタイトル・操作ボタン）
    private func card(_ tag: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("タイトル\(tag)")
                .font(.headline)
            Text("サブタイトル\(tag)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("操作\(tag)") {}
                .buttonStyle(.bordered)
                .accessibilityIdentifier("group.\(tag).button")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func section<Content: View>(
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
    GroupingView()
}
