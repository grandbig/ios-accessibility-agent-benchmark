# identifier / label の付け方の検証（SwiftUI）

Issue #1 の「本命」。親View/子Button への identifier の付け方や、label/identifier の有無で、
XCUITest などの自動操作から要素がどう見えるか（検出できるか・埋もれるか）を実測した。

- 対象画面: `SwiftUIApp/IdentifierLabelView.swift`（タブ「ID/Label」）
- 検証テスト: `SwiftUIAppUITests/IdentifierLabelUITests.swift`（6 ケース・全 pass）
- ツリー: `docs/trees/swiftui-idlabel.txt`
- 実行環境: iPhone SE (3rd generation) / iOS 26.0 Simulator / Xcode 26.4.1

## 結果サマリ

各ケースは「親（HStack）＋ Text "親" ＋ 子 Button」の構成。

| # | パターン | `app.buttons[子id]` | `app.buttons[親id]` | label（VoiceOver名） | 所感 |
| -- | -- | :--: | :--: | -- | -- |
| ① | 子Buttonのみに id | ✅ 検出 | — | '子ボタン1' | 期待通り |
| ② | 親View のみに id | —（子に id なし） | ✅ ボタンとして検出 | '子ボタン2' | **親 id が子に伝播** |
| ③ | 親 + 子 両方に id | ❌ **検出できない** | ✅ 検出 | '子ボタン3' | **親 id が子 id を上書き** |
| ④ | label のみ | —（id なし） | — | '子ボタン4'（ラベルで検出可） | id なしでも label で引ける |
| ⑤ | identifier のみ（図形） | ✅ 検出 | — | **''（空）** | VoiceOver で名前を読めない |
| ⑥ | label + identifier | ✅ 検出 | — | '子ボタン6' | **最も安定** |

## 核心の知見: 親の identifier は子孫へブロードキャストされ、子の identifier を上書きする

ツリー（`docs/trees/swiftui-idlabel.txt`）で挙動の正体が見える。

**② 親View のみに id** — 親に付けた id が、子の Button だけでなく Text "親" にも伝播している:

```
StaticText, identifier: 'idlabel.case2.parent', label: '親'
Button,     identifier: 'idlabel.case2.parent', label: '子ボタン2'
```

**③ 親 + 子 両方に id** — 子 Button は自分の id（`idlabel.case3.child`）ではなく
**親の id（`idlabel.case3.parent`）を持っている**。子の id は消えている:

```
StaticText, identifier: 'idlabel.case3.parent', label: '親'
Button,     identifier: 'idlabel.case3.parent', label: '子ボタン3'   ← case3.child は無い
```

つまり SwiftUI では、`.accessibilityIdentifier` をコンテナ（HStack 等）に付けると、
**配下の全アクセシビリティ要素にその identifier が複製され、子が自分で設定した identifier を上書きする**。
これが「親View に accessibilityIdentifier があると、子View/Button の identifier 検出に影響する」の正体。
結果として、

- 子を `子id` で狙っていた XCUITest / Maestro / AI Agent のセレクタが**壊れる**（③）。
- 同じ identifier を持つ要素が複数生まれ、`Multiple matches` の温床になる（②③: Text と Button が同 id）。

## 補足の知見: ラベルの出どころ

- **⑤ 図形だけのボタン**は identifier では検出できるが label が空。VoiceOver は名前を読めない
  （＝人間向けには不十分。`.accessibilityLabel` の付与が必要）。
- 一方、検証の途中で **SF Symbol（`Image(systemName: "star.fill")`）は自動で label 'Favorite' を持つ**ことも確認した。
  「アイコンだから無名」とは限らないが、`Circle` などの図形・カスタム描画は無名になる。

## 設計指針（この検証から）

1. **操作対象には label と identifier の両方を付ける**（⑥が最も安定。検出も VoiceOver 名も両立）。
2. **親コンテナに安易に `accessibilityIdentifier` を付けない**。子へ伝播・上書きされ、
   子個別の identifier 検出を壊し、重複マッチも招く（②③）。コンテナをまとめたい場合は
   grouping（`accessibilityElement(children:)`）の意味を理解した上で使う（別途検証）。
3. **identifier だけでラベルのない操作対象（図形・カスタム描画）には `accessibilityLabel` を補う**（⑤）。
