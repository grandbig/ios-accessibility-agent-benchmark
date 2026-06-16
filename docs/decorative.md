# 装飾UI / カスタム描画の検証（SwiftUI）

Issue #1 の論点「人間には見えているが、Accessibility Tree 上では意味がない UI がある」を実測する。
ネイティブ標準の手段（Canvas / Gesture のみ / Blur / Glass）で、装飾・カスタム描画が
自動操作（XCUITest など）からどう見えるかを比較した。

- 対象画面: `SwiftUIApp/DecorativeView.swift`（タブ「Decorative」）
- 検証テスト: `SwiftUIAppUITests/DecorativeUITests.swift`（全 pass）
- ツリー: `docs/trees/swiftui-decorative.txt`
- 実行環境: iPhone SE (3rd generation) / iOS 26.0 Simulator / Xcode 26.4.1

## 結果サマリ

| ケース | button として検出 | 要素タイプ | 操作（tap） | 所感 |
| -- | :--: | -- | :--: | -- |
| ① Canvas 描画（a11y なし） | ❌ | Other | — | 見た目はボタンだが**機械はボタンと認識しない** |
| ② Canvas 描画 + a11y | ✅ | Button | ✅ | label + `.isButton` で操作可能に |
| ③ Gesture のみ（a11y なし） | ❌ | Other | — | 同上（タップ意図が伝わらない） |
| ④ Gesture + a11y | ✅ | Button | ✅ | 補完で操作可能に |
| ⑤ Blur の上の Button | ✅ | Button | — | **装飾は検出に影響しない** |
| ⑥ Glass の上の Button | ✅ | Button | — | **装飾は検出に影響しない** |

## ポイント

### 「見た目がボタン」と「機械がボタンと理解できる構造」は別
Canvas で描いただけ／Gesture だけで操作する図形は、`accessibilityIdentifier` を付けても
**汎用の `Other` 要素にしかならず、`button` としては検出されない**。
XCUITest / Maestro / AI Agent は「操作対象（button）」を探すため、これらは見つけられない・操作できない。
Canvas はテキストも描画として埋め込まれるため、ラベルになる文字情報もツリーに出ない。

### accessibility を補えば操作対象になる
`.accessibilityElement()` ＋ `.accessibilityLabel(...)` ＋ `.accessibilityAddTraits(.isButton)` を付けると、
同じ見た目のまま **`button` として検出され、`.tap()` で操作できる**（②④で実証）。
「identifier だけ」では不十分で、**`.isButton` トレイトと label で“操作対象である”という意味情報を与える**必要がある。
（identifier/label 検証の⑤＝図形ボタンが無名になる話の延長線上。あちらは Button だったので検出はできたが、
ここでは Button ですらない＝さらに深刻、という関係。）

### Blur / Glass は検出に影響しない（よくある誤解を解く）
`.ultraThinMaterial`（Blur）や Liquid Glass（`.glassEffect`）の上に置いた通常の `Button` は、
**問題なく `button` として検出された**。装飾は「視覚的な見た目」だけの話で、その上の本物の操作要素の
アクセシビリティを壊すわけではない。「BlurView が原因で検出できない」という見立ては、実際には
**装飾そのものではなく、装飾的な見た目を“本物のコントロールではなく独自描画/Gesture”で作っていたこと**が
原因だった、という整理につながる。

## 設計指針（この検証から）

1. **タップできる見た目には、本物のコントロール（Button など）か、最低限
   `.accessibilityAddTraits(.isButton)` ＋ `.accessibilityLabel` を与える**。
   Canvas / Gesture だけの「ボタン風」は機械から操作できない。
2. **装飾（Blur / Glass / グラデーション等）自体は問題ではない**。
   壊れるのは「装飾的な見た目を独自描画・Gesture で実装し、意味情報を与えていない」とき。
3. カスタム描画で情報を表現する場合は、`accessibilityLabel` / `accessibilityValue` で
   その意味（状態・テキスト）を別途与える。

（UIKit 版の装飾UI ＝ `CALayer` 描画 / `UITapGestureRecognizer` のみ / `UIVisualEffectView` での
対比は今後追加可能）
