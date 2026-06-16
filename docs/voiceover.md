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

## 結論

- VoiceOver 列は **推定ではなく実測**（公式監査 ＋ role/label/value）に基づく。
- 監査が説明欠落と判定したのは **case5（id のみ）** と **装飾UIの無a11y版** のみで、benchmark の予測と一致。
- VoiceOver 向きの grouping（`.combine`/`.ignore`）は label を1つにまとめて自然に読む（◎）が、これは
  自動操作で子要素が埋もれるのとトレードオフ（`docs/grouping.md`）。
- 設計含意は一貫：**操作対象には意味のある label を与える**（VoiceOver にも、人間のテスト項目書・AI Agent にも効く）。
