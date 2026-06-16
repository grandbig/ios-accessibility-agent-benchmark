# grouping の検証（`accessibilityElement(children:)`）

Issue #1 の論点「VoiceOver には親子をまとめた方が自然だが、E2E や AI Agent には子要素が見えづらくなる」を実測する。
同じ「タイトル＋サブタイトル＋操作ボタン」のカードに、grouping なし / `.combine` / `.contain` / `.ignore` を適用して比較した。

- 対象画面: `SwiftUIApp/GroupingView.swift`（タブ「Grouping」）
- 検証テスト: `SwiftUIAppUITests/GroupingUITests.swift`（全 pass）
- ツリー: `docs/trees/swiftui-grouping.txt`
- 実行環境: iPhone SE (3rd generation) / iOS 26.0 Simulator / Xcode 26.4.1

## 結果サマリ

| 適用 | VoiceOver から見た要素 | 操作ボタンの個別検出（XCUITest） | 自動操作の所感 |
| -- | -- | -- | -- |
| ① なし（default） | タイトル / サブタイトル / 操作ボタンの **3要素** | ✅ 単独・一意 | 個別に操作しやすい |
| ② `.combine` | **1要素**（ラベル連結「タイトルB, サブタイトルB」） | ⚠️ id が重複（Multiple matches） | カード全体が1ボタン化、個別操作が埋もれる |
| ③ `.contain` | グループ（コンテナ）＋子は個別 | ✅ 単独・一意 | **まとめつつ個別操作も維持** |
| ④ `.ignore` | **1要素**（独自ラベル「グループDのまとめ」） | △ ツリーには残る（下記） | VoiceOver はまとまるが意味は独自ラベル頼み |

## ツリー実測

**① default** — 3つの独立要素:
```
StaticText, label: 'タイトルA'
StaticText, label: 'サブタイトルA'
Button, identifier: 'group.A.button', label: '操作A'
```

**② .combine** — カード全体が1つの Button 要素（幅343＝カード全体）になり、ラベルが連結される。
元の子要素は中にネストされ、**操作ボタンの id `group.B.button` が「カード全体の要素」と「中の操作ボタン」の両方に付く（重複）**:
```
Button, identifier: 'group.B.button', label: 'タイトルB, サブタイトルB', {16,336.5, 343x109.5}
  StaticText, label: 'タイトルB'
  StaticText, label: 'サブタイトルB'
  Button, identifier: 'group.B.button', label: '操作B'
```
→ VoiceOver は「タイトルB, サブタイトルB」を1つの要素として読む（自然）。一方 XCUITest で
`buttons["group.B.button"]` は**複数マッチ**になり、まとまった要素のラベルは操作内容ではなくタイトル文字列。
個別の「操作B」を狙う自動操作は不安定化する。

**③ .contain** — コンテナの `Other` 要素が子をまとめるが、子は個別の要素のまま:
```
Other, {16,502.5, 343x109.5}                                  ← グループ（コンテナ）
  StaticText, label: 'タイトルC'
  StaticText, label: 'サブタイトルC'
  Button, identifier: 'group.C.button', label: '操作C'         ← 単独・自分のラベルで一意に検出可
```
→ VoiceOver にはグループとして提示しつつ、自動操作は「操作C」を個別に検出・操作できる。両立しやすい。

**④ .ignore（+ 独自ラベル）** — コンテナに独自ラベルが付き、VoiceOver は子を無視してこれだけ読む:
```
Other, {16,668.5, 343x109.5}, label: 'グループDのまとめ'
  StaticText, label: 'タイトルD'        ← VoiceOver からは無視されるが…
  StaticText, label: 'サブタイトルD'
  Button, identifier: 'group.D.button', label: '操作D'   ← XCUITest のツリーには残る（exists=true）
```
→ 注目: `.ignore` は **VoiceOver のフォーカス**から子を外すが、**XCUITest のアクセシビリティツリー**には
子が残り、`buttons["group.D.button"]` は検出できた。「VoiceOver から見たツリー」と「XCUITest/AI Agent から
見たツリー」は必ずしも一致しない、という点自体が重要な観察。

## トレードオフと指針

- **`.combine`**: VoiceOver には「1つの自然な読み上げ」になり良いが、自動操作には不利。
  カード全体が1要素になり個別の操作ボタンが埋もれ、id が重複して `Multiple matches` を招く。
  「カード全体をタップして詳細へ」のような **単一アクションのセル** なら適切。
- **`.contain`**: VoiceOver のグルーピングと、自動操作からの個別検出を**両立**しやすい。
  「グループ内に複数の操作対象がある」UI ではこれが無難。
- **`.ignore`**: VoiceOver の読み上げを独自ラベルに集約できるが、意味情報は `accessibilityLabel` 頼みになる。
  また子が XCUITest ツリーに残る点に注意。
- 共通: **VoiceOver 向けの自然な grouping と、E2E/AI Agent 向けの個別検出性はトレードオフになりうる**。
  複数操作があるなら `.contain`、単一アクションなら `.combine`、と用途で選ぶ。

## SwiftUI vs UIKit: grouping の対比

同じカードを UIKit でも実装（`UIKitApp/GroupingViewController.swift`、検証
`UIKitAppUITests/UIKitGroupingUITests.swift`、ツリー `docs/trees/uikit-grouping.txt`）。
SwiftUI の `accessibilityElement(children:)` に対応する UIKit API:

| SwiftUI | UIKit 相当 |
| -- | -- |
| `.combine` | `isAccessibilityElement = true` ＋ 連結した `accessibilityLabel`（手動） |
| `.contain` | `accessibilityContainerType = .semanticGroup` |
| `.ignore` | `isAccessibilityElement = true` ＋ 独自の `accessibilityLabel` |

### `.contain` ≒ `.semanticGroup`（ほぼ一致）
どちらも「グループ化しつつ子は個別に検出可能」。操作ボタンは単独・自分のラベルで一意に取れる。

### `.combine` vs `isAccessibilityElement = true`（差が出る）

UIKit（B）のツリー — コンテナが1つの `Other` 要素になり、**子の StaticText は吸収されて消える**:
```
Other, {16,298.5, 343x101.5}, label: 'タイトルB, サブタイトルB'   ← 1要素（非インタラクティブ）
  Button, identifier: 'group.B.button', label: '操作B'           ← 重複なし（1個）
```

SwiftUI（②）のツリー（再掲）— カード全体が **Button** になり、**操作ボタンの id が重複**:
```
Button, identifier: 'group.B.button', label: 'タイトルB, サブタイトルB'   ← Button化
  StaticText, label: 'タイトルB'                                          ← StaticTextは残る
  StaticText, label: 'サブタイトルB'
  Button, identifier: 'group.B.button', label: '操作B'                    ← id 重複（Multiple matches）
```

| 観点 | SwiftUI `.combine` | UIKit `isAccessibilityElement=true` |
| -- | -- | -- |
| まとまった要素の型 | **Button**（中に button があるため） | **Other**（非インタラクティブ） |
| 連結ラベル | 自動生成（"タイトルB, サブタイトルB"） | **手動で設定が必要** |
| 子 StaticText | ツリーに残る（ネスト） | **吸収されて消える** |
| 操作ボタンの id | **重複**（Multiple matches の温床） | 重複しない（1個） |

→ SwiftUI の `.combine` は「自動で連結ラベル」が便利な反面、**Button 化＋ id 重複**という自動操作の落とし穴がある。
UIKit は手動でラベルを組む手間がある代わりに、**id 重複は起きずツリーがすっきり**する。

### 共通の観察: VoiceOver のフォーカス ≠ XCUITest のツリー
SwiftUI `.ignore`・UIKit `isAccessibilityElement=true` のいずれでも、VoiceOver は子を無視して
コンテナのラベルだけを読むが、**操作ボタンは XCUITest のアクセシビリティツリーには残り、検出できた**。
「VoiceOver から見たツリー」「XCUITest / AI Agent から見たツリー」は別物、という点が一貫して確認できる。
