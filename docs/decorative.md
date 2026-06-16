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

#### 属性ごとの役割分担（identifier ≠ trait）

「`accessibilityIdentifier` を付ければ機械から操作できる」は誤り。実測（①）では、
`accessibilityIdentifier("deco.canvas")` を**付けていても** `button` にはならず `Other` 止まりだった。
3つの属性は役割が異なる:

| 属性 | 役割 | これ単体では |
| -- | -- | -- |
| `accessibilityIdentifier` | 固定キーで**探す**（主にテスト用のセレクタ） | ❌ 「ボタンである」とは伝わらない（`Other` のまま） |
| `accessibilityLabel` | **名前・意味**（VoiceOver や AI が「何か」を理解する） | △ 名前は付くが「操作対象」とは限らない |
| `accessibilityAddTraits(.isButton)` | **役割（ロール）= 操作対象である**と宣言 | ✅ これで `button` として認識される |

→ カスタムUIを操作可能にするには **`.accessibilityElement()` + `accessibilityLabel`（意味）+ `.isButton`（役割）**
の3点が要る。`accessibilityIdentifier` は“探すための鍵”であって“操作対象である”ことは伝えない。

#### 「AI から検知できない」は AI の種類による
- **アクセシビリティツリー型**（XCUITest / Maestro / VoiceOver / agent-device など多くのモバイル AI Agent）:
  上記のとおり、trait/label がないと**操作対象として見つけられない・操作できない**。
- **ビジョン型**（スクリーンショット + LLM）: 見た目で判断するため座標タップは可能かもしれないが、
  「これは何のボタンか」という意味は分からず、信頼性・再現性が落ちる。

本ベンチマークの対象ツールは基本ツリー依存なので、結論は
**「意味情報（label）と役割（trait）を与えないと、機械は操作対象と認識しない」**。

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

## SwiftUI vs UIKit: 装飾UI の対比

同じケースを UIKit でも実装（`UIKitApp/DecorativeViewController.swift`、検証
`UIKitAppUITests/UIKitDecorativeUITests.swift`、ツリー `docs/trees/uikit-decorative.txt`）。
SwiftUI の各手段に対応する UIKit 実装:

| SwiftUI | UIKit 相当 |
| -- | -- |
| Canvas 描画 | `UIView.draw(_:)` によるカスタム描画 + `UITapGestureRecognizer` |
| Gesture のみ | プレーンな `UIView` + `UITapGestureRecognizer` |
| accessibility 補完 | `isAccessibilityElement = true` + `accessibilityLabel` + `accessibilityTraits = .button` |
| Blur | `UIVisualEffectView(effect: UIBlurEffect(...))` |
| Glass | `UIVisualEffectView(effect: UIGlassEffect())`（iOS 26、古いOSは Blur フォールバック） |

### 結果は SwiftUI と同一

| ケース | button 検出 | 操作 | SwiftUI と比較 |
| -- | :--: | :--: | -- |
| ① カスタム描画（a11yなし） | ❌（Other） | — | 同じ |
| ② カスタム描画 + a11y | ✅ | ✅ | 同じ |
| ③ Gestureのみ（a11yなし） | ❌（Other） | — | 同じ |
| ④ Gesture + a11y | ✅ | ✅ | 同じ |
| ⑤ Blurの上のButton | ✅ | — | 同じ |
| ⑥ Glassの上のButton | ✅ | — | 同じ |

→ **装飾UI / カスタム描画の振る舞いは SwiftUI と UIKit でほぼ同一**。
identifier/label の伝播（SwiftUI 特有）や grouping（`.combine` の Button 化）のように
**フレームワークで差が出る論点とは異なり**、「カスタム描画・Gesture のみは意味情報を与えないと
操作対象と認識されない」「装飾そのものは検出に影響しない」は **両フレームワーク共通の原則**。
UIKit では `isAccessibilityElement` + `accessibilityLabel` + `accessibilityTraits = .button` の
3点で SwiftUI と同様に操作可能になる。
