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

SwiftUI では、`.accessibilityIdentifier` をコンテナ（HStack 等）に付けると、
**配下の全アクセシビリティ要素にその identifier が複製され、子が自分で設定した identifier を上書きする**。
コード（`SwiftUIApp/IdentifierLabelView.swift`）と、結果のツリー（`docs/trees/swiftui-idlabel.txt`）を
並べると挙動の正体が見える。

### ② 親View のみに id を付けた場合

```swift
HStack {
    Text("親")
    Button("子ボタン2") {}          // ← 子には identifier を付けていない
        .buttonStyle(.bordered)
}
.accessibilityIdentifier("idlabel.case2.parent")   // ← 親(HStack)に付けた id
```

結果のツリー — 親に付けた `idlabel.case2.parent` が、子 Button **と** 兄弟の Text "親" の
**両方**の identifier になる:

```
StaticText, identifier: 'idlabel.case2.parent', label: '親'
Button,     identifier: 'idlabel.case2.parent', label: '子ボタン2'
```

→ `app.buttons["idlabel.case2.parent"]` で子ボタンが取れてしまう（子は無印のはずなのに）。

### ③ 親View + 子Button の両方に id を付けた場合

```swift
HStack {
    Text("親")
    Button("子ボタン3") {}
        .buttonStyle(.bordered)
        .accessibilityIdentifier("idlabel.case3.child")    // ← 子に付けた id
}
.accessibilityIdentifier("idlabel.case3.parent")           // ← 親に付けた id
```

結果のツリー — 子 Button は**自分で付けた `idlabel.case3.child` ではなく、
親の `idlabel.case3.parent` を持つ**（子の id は消えている）:

```
StaticText, identifier: 'idlabel.case3.parent', label: '親'
Button,     identifier: 'idlabel.case3.parent', label: '子ボタン3'   ← case3.child は存在しない
```

→ `app.buttons["idlabel.case3.child"]` は**検出不能**、`app.buttons["idlabel.case3.parent"]` だけが当たる。

### 「親に付けた id」→「子の最終的な id」の対応

| 親(コンテナ)に付けた id | 子Button が元々持っていた id | 子Button の最終的な id | 子を元の id で検出 |
| -- | -- | -- | :--: |
| `idlabel.case2.parent` | （なし） | `idlabel.case2.parent` | — |
| `idlabel.case3.parent` | `idlabel.case3.child` | `idlabel.case3.parent`（親で上書き） | ❌ |

これが「親View に accessibilityIdentifier があると、子View/Button の identifier 検出に影響する」の正体。
結果として、

- 子を `子id` で狙っていた XCUITest / Maestro / AI Agent のセレクタが**壊れる**（③）。
- 同じ identifier を持つ要素が複数生まれ、`Multiple matches` の温床になる（②③: Text と Button が同 id）。

## 補足の知見: ラベルの出どころ

⑤は **Canvas で独自描画したボタンではなく、ごく普通の SwiftUI `Button`** である。
ただし中身（label）がテキストを持たない図形（`Circle`）なので、ボタン要素としては
公開され・タップも効くが、アクセシビリティラベルが空になる。

```swift
Button {
} label: {
    Circle()                       // ← 中身がテキストなしの図形
        .fill(Color.accentColor)
        .frame(width: 24, height: 24)
}
.accessibilityIdentifier("idlabel.case5.noLabelButton")
// → button要素として検出可（identifier）。ただし label='' で VoiceOver は名前を読めない。
```

ラベルの出どころには段階がある:

| ボタンの中身 | button 要素として検出 | アクセシビリティ label | 例 |
| -- | :--: | -- | -- |
| テキスト | ✅ | 自動で付く | `Button("送信")`（①④⑥） |
| SF Symbol | ✅ | 自動で付く場合あり | `Image(systemName: "star.fill")` → 'Favorite' |
| 図形・テキストなし画像 | ✅ | **空になる**（要 `accessibilityLabel`） | `Circle()`（⑤） |
| Canvas / Gesture のみ | ✗ になりがち | そもそも button 要素にならない | 「装飾UI」検証で別途扱う |

- ⑤のような「テキストを持たない見た目のボタン」は、identifier では操作できても
  VoiceOver では無名になるため、`.accessibilityLabel("...")` を補う必要がある。
- 検証の途中で **SF Symbol（`star.fill`）は自動で label 'Favorite' を持つ**ことも確認した。
  「アイコンだから無名」とは限らない。
- **Canvas で独自描画したボタンや Gesture のみの操作**は⑤よりさらに深刻で、そもそも
  button 要素として認識されない。`accessibilityLabel` だけでなく `accessibilityAddTraits(.isButton)`
  や `accessibilityAction` で「操作対象である」という意味情報ごと与える必要がある
  （Issue #1 の「装飾UI」セクションで別途検証）。

## 設計指針（この検証から）

1. **操作対象には label と identifier の両方を付ける**（⑥が最も安定。検出も VoiceOver 名も両立）。
2. **親コンテナに安易に `accessibilityIdentifier` を付けない**。子へ伝播・上書きされ、
   子個別の identifier 検出を壊し、重複マッチも招く（②③）。コンテナをまとめたい場合は
   grouping（`accessibilityElement(children:)`）の意味を理解した上で使う（別途検証）。
3. **テキストを持たない見た目の操作対象（図形・アイコン・画像のボタン）には `accessibilityLabel` を補う**（⑤）。
   identifier だけでは機械は操作できても VoiceOver では無名になる。
   （Canvas 独自描画や Gesture のみの操作は、さらに `accessibilityAddTraits(.isButton)` /
   `accessibilityAction` も必要。「装飾UI」検証で扱う）
