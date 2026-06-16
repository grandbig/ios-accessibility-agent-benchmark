# VoiceOver の実測

`docs/summary.md` の VoiceOver 列を「ツリーからの推定」ではなく**実測**で裏づけるための計測。

## 計測方法（2つ）

1. **Apple 公式のアクセシビリティ監査**：`XCUIApplication.performAccessibilityAudit()`（Accessibility Inspector の
   Audit と同等のチェック）を各画面で実行し、**`.sufficientElementDescription`（要素の説明＝
   accessibilityLabel の欠落）**を計測する。「VoiceOver が名前を読めない要素」を客観的に検出できる。
   テスト: `SwiftUIAppUITests/VoiceOverAuditTests.swift`（全 pass）。
2. **VoiceOver が読み上げる内容**：各要素の **role（elementType）/ label / value** を実測（`docs/trees/*` と同じ採取）。
   VoiceOver は「label・ロール・値」を読み上げるため、これが読み上げ内容の実測になる。

> 注: `performAccessibilityAudit` は Contrast / TextClipped など他の監査も行うが、これらはサンプルの配色・
> レイアウト由来で本テーマ（機械可読性）とは別軸のため、ここでは説明欠落に絞る。
> また**読み上げ「順序」の細部**（VoiceOver 実機のフォーカス遷移）は未計測で、スライド用に実機/シミュレータで
> VoiceOver を動かした録画を別途用意する（Issue #2 のスライド素材）。

## 監査結果（説明欠落＝VoiceOver が名前を読めない要素）

| 画面 | 説明欠落の要素 | 件数 |
| -- | -- | :--: |
| basics（基本要素） | （なし） | 0 |
| idlabel | `idlabel.case5.noLabelButton`（identifier のみ・ラベルなし図形ボタン） | 1 |
| grouping | （なし） | 0 |
| decorative | `deco.canvas` / `deco.gesture`（accessibility を与えていない Canvas / Gesture） | 2 |

→ **「ラベルを与えていない操作対象（case5・装飾UIの無a11y版）」だけが、Apple 公式監査で説明欠落と判定された。**
我々の事前分析（identifier だけでは VoiceOver で無名／装飾UIは意味情報が要る）が客観監査で裏づけられた。

## VoiceOver が読み上げる内容（role / label / value の実測）

代表ケース（`docs/trees/swiftui-*.txt` の実測値より）：

| UI設計 | role | label | value | VoiceOver の読み（概略） |
| -- | -- | -- | -- | -- |
| Button: label + id | button | 'タップ回数: 0' | — | 「タップ回数: 0、ボタン」 ◎ |
| Toggle（ラベル付き） | switch | 'トグル' | 0 | 「トグル、スイッチ、オフ」 ◎ |
| id のみ（case5） | button | **（空）** | — | 名前なし＝**監査で説明欠落**。VoiceOver は意味を伝えられない △ |
| `.combine`（カード1要素化） | button | 'タイトルB, サブタイトルB' | — | 連結ラベルを1要素として自然に読む ◎ |
| `.ignore`（独自ラベル） | （コンテナ） | 'グループDのまとめ' | — | 独自ラベルだけ読む ◎（意味はラベル頼み） |
| Canvas/Gesture（a11yなし） | other | **（空）** | — | 無名要素＝**監査で説明欠落**。意味が伝わらない △〜× |
| 同上 + label + `.isButton` | button | '送信' | — | 「送信、ボタン」 ◎ |

## performAccessibilityAudit の限界（検出できること / できないこと）

本監査は「VoiceOver 体験の合否判定器」ではなく、「**説明欠落の検出器**（特に“名前の欠落”に強い）」である。

検出できること：

- アクセシビリティ要素として存在するのに、**説明（accessibilityLabel）が空 or 不十分**な要素
  （＝VoiceOver はフォーカスするが意味のある名前を読めない）。

検出できない / 苦手なこと：

1. **そもそもアクセシビリティツリーに無い要素**は対象外。identifier も label も付けない完全な装飾要素は
   「要素ですらない」ため監査に現れず、欠落としても報告されない（今回 `deco.canvas` が検出されたのは、
   検証用に `accessibilityIdentifier` を付けて Other 要素になっていたため）。
2. **ラベルは「ある」が中身が不適切**なケースは見逃す。無意味な文字列でも「説明は存在する」と判定されパスしうる
   （＝有無は見るが、質・正確さは見ない）。
3. **読み上げ順序・フォーカス遷移**は評価しない。
4. **grouping の良し悪し**（`.combine`/`.ignore` で意味がまとまっているか）は判定しない。
5. **静的な監査**であり「実機 VoiceOver を動かして聞く」ものではない（近似・ヒューリスティック）。

→ 「VoiceOver で本当に意味が伝わるか／順序は自然か」までは保証しないため、**最終確認は実機 VoiceOver の
読み上げを聞く**のが必要（スライド用の実機録画は Issue #2 の残タスク）。

## 結論

- VoiceOver 列は **推定ではなく実測**（公式監査 ＋ role/label/value）に基づく。
- 監査が説明欠落と判定したのは **case5（id のみ）** と **装飾UIの無a11y版** のみで、benchmark の予測と一致。
- VoiceOver 向きの grouping（`.combine`/`.ignore`）は label を1つにまとめて自然に読む（◎）が、これは
  自動操作で子要素が埋もれるのとトレードオフ（`docs/grouping.md`）。
- 設計含意は一貫：**操作対象には意味のある label を与える**（VoiceOver にも、人間のテスト項目書・AI Agent にも効く）。
