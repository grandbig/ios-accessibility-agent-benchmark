# SwiftUI vs UIKit — 同一 UI のアクセシビリティ差分

同じ「基本要素」画面を SwiftUI（`SwiftUIApp/BasicElementsView.swift`）と
UIKit（`UIKitApp/BasicElementsViewController.swift`）で、**同じ identifier 命名規約**で実装し、
アクセシビリティツリーと XCUITest での操作性を比較した結果。

- 実行環境: iPhone SE (3rd generation) / iOS 26.0 Simulator / Xcode 26.4.1
- 基準値テスト: 両アプリとも **10 / 10 passed**
  （`SwiftUIAppUITests/BasicElementsUITests`、`UIKitAppUITests/UIKitBasicElementsUITests`）
- ツリー: `docs/trees/swiftui-*.txt` / `docs/trees/uikit-*.txt`（`scripts/dump-accessibility-trees.sh`）

## 最大の差分: Toggle / UISwitch

### XCUITest での操作
| | SwiftUI `Toggle("トグル")` | UIKit `UILabel` + `UISwitch` |
| -- | -- | -- |
| `.tap()`（要素中央）で切替 | ❌ できない（座標オフセットが必要） | ✅ できる |
| Switch 要素のフレーム幅 | **343pt**（行全体） | **63pt**（スイッチ本体のみ） |
| VoiceOver ラベル | ✅ 'トグル' | ✅ 'トグル' |

UIKit 版の toggle テストは座標オフセットなしの素の `toggle.tap()` で成功する。
SwiftUI 版は `.tap()` では切り替わらず、`coordinate(withNormalizedOffset:)` が必要だった
（詳細は `docs/xcuitest-baseline.md` 知見1）。

### ツリー構造の違い（実測）

**SwiftUI** — ラベルが Switch の**子要素**として取り込まれ、Switch 自体が横幅いっぱいに広がる:

```
Switch, {{16, 329.5}, {343, 52.5}}, identifier: 'basics.toggle', label: 'トグル', value: 0
  StaticText, {{32, 345.5}, {48, 20.5}}, label: 'トグル'
```

**UIKit** — ラベル（StaticText）と Switch が**別々の兄弟要素**。Switch は右端のコンパクトな本体だけ:

```
StaticText, {{32, 339.5}, {48, 20.5}}, label: 'トグル'
Switch, {{282, 335.5}, {63, 28}}, identifier: 'basics.toggle', label: 'トグル', value: 0
```

注目: UIKit の `UISwitch` には `accessibilityLabel` を明示設定していないが、
ツリー上では `label: 'トグル'` を持つ（隣接する `UILabel` が関連付けられたとみられる）。
→ UIKit の素直な実装は **「VoiceOver 名あり」＋「コンパクトで `.tap()` 可能」** を自動的に両立する。
一方 SwiftUI の `Toggle("ラベル")` は名前は付くが要素が広がり `.tap()` が外れる。
SwiftUI で両立させるには `.labelsHidden()` + `.accessibilityLabel(...)` が要る
（`docs/xcuitest-baseline.md` 知見1-b）。

## その他の基本要素

| 要素 | SwiftUI フレーム | UIKit フレーム | 所感 |
| -- | -- | -- | -- |
| Button (`basics.primaryButton`) | {{16, 277}, {343, 52.5}} | {{32, 286.5}, {311, 22}} | どちらも検出・`.tap()` 可。SwiftUI はセル幅、UIKit はラベル幅 |
| TextField (`basics.textField`) | {{32, 455.5}, {311, 22}} | {{32, 446}, {311, 22}} | ほぼ同等。検出・入力とも可 |
| StaticText / List item / Tab / Modal / Alert / ScrollView | — | — | いずれも両フレームワークで検出・操作可（差は軽微） |

## まとめ

- **「`.tap()` で操作できるか」はフレームワークと実装イディオムで変わる**。同じ「ラベル付きスイッチ」でも、
  SwiftUI `Toggle` は単一の広い要素、UIKit は「ラベル＋コンパクトなスイッチ」の別要素になる。
- UIKit の慣用的な実装は VoiceOver 名と自動操作性を両立しやすいが、SwiftUI の `Toggle("ラベル")` は
  そのままだと自動操作（中央タップ）に弱く、明示的な調整が要る。
- これは「Accessibility 設計（＝機械から見たツリーの作られ方）が、テスト・自動操作・AI Agent の
  操作可否を左右する」という本テーマの中心的な実例。
