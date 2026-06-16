import SwiftUI

/// 装飾UI / カスタム描画の検証画面。
///
/// 「人間には見えているが、Accessibility Tree 上では意味がない（操作対象と認識されない）UI」を、
/// ネイティブ標準の手段（Canvas / Gesture のみ / Blur / Glass）で実証する。
/// 各ケースで「無アクセシビリティ版」と「accessibility を補った版」を対比し、
/// Blur / Glass は検出に影響しない（＝装飾は視覚だけの問題）ことも確認する。
/// 命名規約: `deco.*`
struct DecorativeView: View {
    @State private var lastTapped = "なし"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text("最後にタップ: \(lastTapped)")
                        .font(.footnote)
                        .accessibilityIdentifier("deco.lastTapped")

                    canvasNoA11y
                    canvasFixed
                    gestureNoA11y
                    gestureFixed
                    blurButton
                    glassButton
                }
                .padding()
            }
            .navigationTitle("Decorative")
        }
    }

    // ① Canvas で描いたボタン風UI（アクセシビリティ指定なし）
    private var canvasNoA11y: some View {
        section("① Canvas描画（アクセシビリティなし）") {
            drawnButton(text: "送信")
                .onTapGesture { lastTapped = "canvas" }
                .accessibilityIdentifier("deco.canvas")
        }
    }

    // ② ①に accessibility（ラベル + isButton トレイト）を補った版
    private var canvasFixed: some View {
        section("② Canvas描画 + accessibility") {
            drawnButton(text: "送信")
                .onTapGesture { lastTapped = "canvasFixed" }
                .accessibilityElement()
                .accessibilityLabel("送信")
                .accessibilityAddTraits(.isButton)
                .accessibilityIdentifier("deco.canvasFixed")
        }
    }

    // ③ Gesture のみで操作する図形（アクセシビリティ指定なし）
    private var gestureNoA11y: some View {
        section("③ Gestureのみ（アクセシビリティなし）") {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green)
                .frame(width: 120, height: 44)
                .onTapGesture { lastTapped = "gesture" }
                .accessibilityIdentifier("deco.gesture")
        }
    }

    // ④ ③に accessibility を補った版
    private var gestureFixed: some View {
        section("④ Gesture + accessibility") {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green)
                .frame(width: 120, height: 44)
                .onTapGesture { lastTapped = "gestureFixed" }
                .accessibilityElement()
                .accessibilityLabel("実行")
                .accessibilityAddTraits(.isButton)
                .accessibilityIdentifier("deco.gestureFixed")
        }
    }

    // ⑤ Blur（.ultraThinMaterial）の上の通常の Button → 検出に影響しないはず
    private var blurButton: some View {
        section("⑤ Blur の上の Button") {
            ZStack {
                LinearGradient(colors: [.purple, .orange], startPoint: .leading, endPoint: .trailing)
                Button("ブラーの上") { lastTapped = "blur" }
                    .buttonStyle(.borderedProminent)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityIdentifier("deco.blurButton")
            }
            .frame(height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // ⑥ Glass（Liquid Glass）の上の通常の Button → 検出に影響しないはず
    private var glassButton: some View {
        section("⑥ Glass の上の Button") {
            ZStack {
                LinearGradient(colors: [.blue, .green], startPoint: .leading, endPoint: .trailing)
                glassButtonContent
            }
            .frame(height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private var glassButtonContent: some View {
        if #available(iOS 26.0, *) {
            Button("グラスの上") { lastTapped = "glass" }
                .padding()
                .glassEffect(.regular, in: .rect(cornerRadius: 12))
                .accessibilityIdentifier("deco.glassButton")
        } else {
            Button("グラスの上") { lastTapped = "glass" }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityIdentifier("deco.glassButton")
        }
    }

    /// Canvas で「ボタンらしき見た目」を描く（テキストも Canvas で描画するため、
    /// 通常のアクセシビリティ要素にはならない）。
    private func drawnButton(text: String) -> some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            context.fill(Path(roundedRect: rect, cornerRadius: 8), with: .color(.blue))
            let resolved = context.resolve(Text(text).foregroundColor(.white).bold())
            context.draw(resolved, at: CGPoint(x: size.width / 2, y: size.height / 2))
        }
        .frame(width: 120, height: 44)
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
    DecorativeView()
}
