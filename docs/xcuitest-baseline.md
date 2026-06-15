# XCUITest 基準値（ものさし） — SwiftUI 基本要素

「普通に作った」SwiftUI の基本要素画面（`SwiftUIApp/BasicElementsView.swift`）に対し、
Apple 純正の UI 自動操作（XCUITest）で各要素が **検出できるか / 操作できるか** を測定した結果。
以降の identifier/label・grouping・装飾UI などの検証は、この基準値との差分で評価する。

- テスト: `SwiftUIAppUITests/BasicElementsUITests.swift`
- 実行環境: iPhone SE (3rd generation) / iOS 26.0 Simulator / Xcode 26.4.1
- 結果: **10 / 10 passed**

## 結果サマリ

| 基本要素 | 検出 (exists) | 操作 (tap/type) | 備考 |
| -- | :--: | :--: | -- |
| Text（静的テキスト） | ✅ | — | identifier で一意に検出可 |
| Button | ✅ | ✅ | タップでラベル更新を確認 |
| Toggle | ✅ | ✅ | ⚠️ 下記「知見1」参照 |
| TextField | ✅ | ✅ | `typeText` で値反映を確認 |
| SecureField | ✅ | ✅ | 値はマスクされるため非空のみ確認 |
| List item | ✅ | — | 遅延読み込みのためスクロール後に検出 |
| Tab | ✅ | ✅ | ラベル文字列で検出・切替可 |
| Modal (sheet) | ✅ | ✅ | 表示・閉じるとも可 |
| Alert | ✅ | ✅ | ⚠️ 下記「知見2」参照 |
| ScrollView 内の要素 | ✅ | — | 非遅延 HStack のため画面外要素もツリー上に存在 |

→ 命名規約 `<screen>.<element>` で `accessibilityIdentifier` を付ければ、
基本要素は XCUITest で**一通り検出・操作できる**ことを確認（＝基準値が成立）。

## 検証中に得られた知見

### 知見1: ラベル付き SwiftUI `Toggle` は `.tap()`（中央タップ）では切り替わらない
`Toggle` 自体に `accessibilityIdentifier` を付与し、`app.switches[...]` で
**Toggle を直接指定してタップ**しても、`.tap()`（要素中央タップ）では値が `0` のまま変化しなかった。
これは `List` 内に限らず、`VStack` 直下に置いた単独の `Toggle` でも同様だった。

タップ位置を変えて実測した結果（iPhone SE / 画面幅 375pt、Toggle フレーム幅 343pt）:

| タップ位置 | 結果 |
| -- | -- |
| 左ラベル端 (dx=0.05) | 変化なし |
| 中央 (dx=0.50) ＝ `.tap()` 相当 | 変化なし |
| 右スイッチ本体 (dx=0.92) | **切替OK** |

**原因**: ラベル付き `Toggle` は「ラベル＋余白＋スイッチ本体」全体で 1 つの switch 要素になり、
フレームが横幅いっぱい（343pt）に広がる。視覚的なスイッチ本体は右端の約 60pt だけ。
`.tap()` は要素の幾何中央（x ≈ 187）を叩くため、ラベルとスイッチの間の**余白**に当たり、
トグルが反応しない。

**操作する正しい方法**: スイッチ本体（右端）を座標指定でタップする。

```swift
// 右端付近を狙う（端からの固定オフセットの方が画面幅に依存しにくい）
toggle.coordinate(withNormalizedOffset: CGVector(dx: 1.0, dy: 0.5))
      .withOffset(CGVector(dx: -30, dy: 0)).tap()
```

**設計で解決する方法**: `.labelsHidden()` でラベルを外すと、switch 要素のフレームが
スイッチ本体だけ（実測 61pt）に縮み、`.tap()`（中央タップ）でそのまま切り替わる。

```
ラベルあり:       frame 幅 343 → .tap() ❌
.labelsHidden():  frame 幅  61 → .tap() ✅
```

→ **「identifier を付ける」＝検出はできるが、安定した操作には不十分**。
要素フレームと実際のヒット領域（スイッチ本体）がずれるため。
UIKit の `UISwitch` は独立した小さなフレームを持つので `.tap()` で素直に切り替わるのと対照的。
「同じスイッチでも、フレームの作られ方の違いで機械からの操作しやすさが変わる」例。
（補足: `Form` 内では行全体タップでトグルが切り替わるため、コンテナによっても挙動が変わる）

### 知見1-b: ラベルの持たせ方による「VoiceOver ↔ 自動操作」のトレードオフ
「ラベルを `Text` に分離し、`Toggle` は `.labelsHidden()` にして `HStack` で並べれば
`.tap()` が通るのでは？」を 3 パターンで実測した結果:

| パターン | switch フレーム幅 | VoiceOver ラベル | `.tap()`(中央) |
| -- | :--: | :--: | :--: |
| ① `Toggle("トグル", isOn:)` | 343 | ✅ "トグル" | ❌ 変化なし |
| ② `Text("トグル")` + `Toggle("").labelsHidden()` | 61 | ❌ **""（無名）** | ✅ 切替OK |
| ③ ② + `.accessibilityLabel("トグル")` | 61 | ✅ "トグル" | ✅ 切替OK |

- **①** はラベルとスイッチが 1 つの要素になり VoiceOver は「トグル, スイッチ, オフ」と
  まとめて読む（VoiceOver には理想）が、フレームが広く `.tap()` が当たらない。
- **②**（ラベル分離案）は `.tap()` は通るが、`Text` と switch が**別々の要素**になり、
  switch 自体の名前が空になる。VoiceOver はラベルとスイッチを別々に読み、スイッチは
  「スイッチ, オフ」と**無名**で読み上げられてしまう（アクセシビリティの劣化）。
- **③** `.labelsHidden()` + `.accessibilityLabel("トグル")` が両立解。
  `.tap()` で操作でき、かつ switch に名前も付く。

→ **VoiceOver 向きの素直な書き方（①）と、自動操作・AI Agent 向きの検出性（②）は
そのままだとトレードオフになる**。`.accessibilityLabel` で意味情報を明示的に補えば
（③）両立できる、という設計指針が実測で裏付けられた。本発表の中心的な論点。

### 知見2: Alert の "OK" ボタンは label 指定だと複数マッチする
`app.alerts.buttons["OK"]` が "Multiple matching elements found" となりタップに失敗した。
`.firstMatch` で一意化して解決。アラート要素の検出は label 単独だと不安定になりうる。

### 補足: Tab はラベルで識別される
タブの内容ビューに付けた `accessibilityIdentifier` はタブバー側ボタンには伝播せず、
タブは `app.tabBars.buttons["基本要素"]` のようにラベル文字列で識別する必要がある。

## 再現方法

```sh
xcodegen generate
xcodebuild -project AccessibilityBenchmark.xcodeproj \
  -scheme SwiftUIApp \
  -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.0' \
  test
```
