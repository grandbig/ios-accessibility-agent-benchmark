# 総合比較表 — UI設計 × ツール

各 UI 設計が、VoiceOver / XCUITest / Maestro / agent-device からどう見える・操作できるかの総合まとめ。
個別の実測・ツリー・コードは各 `docs/*.md` と `docs/trees/`、テストは `*UITests` を参照。

## 凡例

- ◎ = 安定して検出・操作できる
- ○ = 検出できるが注意点あり（テキスト変更・重複・名前の質など）
- △ = 条件付き・不安定（座標が要る／意図とずれる／id か label の片方のみ）
- × = 操作対象として検出できない

## 計測の前提（重要）

- **XCUITest**: 全ケースを直接計測（SwiftUI / UIKit、`*UITests` で固定化）。
- **Maestro / agent-device**: 見出し級のケース（Toggle、identifier 上書き、装飾UI）を直接計測し、
  XCUITest と結論一致を確認済み。それ以外のセルは「3ツールとも同一のアクセシビリティツリーに依存し、
  計測した範囲ですべて一致した」ことから同等と判断（＝ツリー由来の挙動は一致する、というのが本検証の結論）。
- **VoiceOver**: **実測**。Apple 公式の `performAccessibilityAudit()`（`.sufficientElementDescription`＝
  説明欠落の検出）＋ 各要素の role / label / value（VoiceOver の読み上げ内容）で計測
  （`docs/voiceover.md`、`SwiftUIAppUITests/VoiceOverAuditTests.swift`）。監査は **case5（id のみ）と
  装飾UIの無a11y版のみを説明欠落と判定**し、事前分析と一致。なお実機 VoiceOver の読み上げ**順序**の
  細部は未計測（スライド用に別途録画予定）。

## 比較表（SwiftUI 基準）

| UI設計 | VoiceOver | XCUITest | Maestro | agent-device | 所感 |
| -- | :--: | :--: | :--: | :--: | -- |
| Button に label + identifier | ◎ | ◎ | ◎ | ◎ | **最安定**。id駆動・label駆動・VoiceOver すべて◎ |
| Button に label のみ（id なし） | ◎ | ○ | ○ | ◎ | 人間/AI/VoiceOver に効くが、テキスト変更・重複に弱い |
| Button に identifier のみ（ラベルなし図形） | △ | ○ | ○ | ○ | 機械は id で操作可だが、VoiceOver/AI で名前が無意味（id が露出） |
| 親コンテナに identifier（子は無印） | ○ | △ | △ | △ | 親 id が子へ**伝播**。id駆動の検出が乱れる（label駆動は可） |
| 親View + 子 両方に identifier | ○ | △ | △ | △ | 子 id が親に**上書き**され消える。id駆動が壊れる（label駆動は可） |
| 親に identifier + `.contain`（回避策） | ◎ | ◎ | ◎ | ◎ | 公式回避策。子 id を保持しつつコンテナにも id（UIKit と同構造） |
| grouping `.combine`（カード1要素化） | ◎ | △ | △ | △ | VoiceOver 自然。自動操作は子が埋もれ・id 重複（単一アクション向け） |
| grouping `.contain` | ◎ | ◎ | ◎ | ◎ | VoiceOver と自動操作を**両立**（複数操作のグループ向け） |
| grouping `.ignore`（独自ラベル） | ◎ | △ | △ | △ | VoiceOver を独自ラベルに集約。意味はラベル頼み・子は無視 |
| Toggle（ラベル付き・標準） | ◎ | △ | △ | △ | フレームが行幅に広がり**中央タップが外れる**。右端 point か `.labelsHidden()`+`accessibilityLabel` が要る |
| カスタム描画(Canvas)/Gesture のみ（a11yなし） | × | × | × | × | 見た目はボタンでも**操作対象と認識されない**（Other 止まり） |
| 同上 + `accessibilityLabel` + `.isButton` | ◎ | ◎ | ◎ | ◎ | trait + label で**操作対象になる**（装飾UIを救う方法） |
| Blur / Glass 装飾の上の Button | ◎ | ◎ | ◎ | ◎ | **装飾は検出に影響しない**（「Blurが原因」は誤解） |

## SwiftUI と UIKit で挙動が変わる行（差分）

上表は SwiftUI 基準。次の3点は UIKit だと結果が変わる：

| 観点 | SwiftUI | UIKit |
| -- | -- | -- |
| 親View に identifier | 子へ**伝播・上書き**（id駆動 △） | View 単位で独立、**伝播しない**（子 id は無事） |
| Toggle（ラベル付き） | switch が行幅 343pt、**中央タップ外す**（△） | `UISwitch` は幅 63pt、**中央タップで切替（◎）** |
| grouping `.combine` 相当 | カード全体が **Button** 化＋id 重複 | `isAccessibilityElement` で **Other** 化・id 重複なし（ラベルは手動連結） |

→ 「親 identifier の上書き」「Toggle 中央タップ外し」「`.combine` の Button 化」は **SwiftUI 特有**。
装飾UI（カスタム描画/Gesture/Blur/Glass）の挙動は **SwiftUI / UIKit 共通**。

## 全体の結論

1. **操作対象には「意味のある label」＋「一意な identifier」＋「正しい role(trait)」を与える**のが最安定
   （id駆動・label駆動・VoiceOver・AI のすべてに効く）。
2. **id 駆動と label 駆動で“効く問題”が違う**：親 identifier の上書きは id 駆動を全ツールで壊し（label駆動は無事）、
   ラベルなしは label 駆動/VoiceOver で id が露出する。人間のテスト項目書・AI Agent は label 中心。
3. **親コンテナに安易に identifier を付けない**。付けるなら `accessibilityElement(children: .contain)` を併用。
4. **VoiceOver 向きの grouping（`.combine`/`.ignore`）と自動操作の個別検出はトレードオフ**。
   複数操作があるなら `.contain`。
5. **「タップできる見た目」と「機械が操作対象と理解する構造」は別**。Canvas/Gesture だけのボタン風には
   `accessibilityLabel` + `.isButton` を与える。**装飾（Blur/Glass）自体は無害**。
6. これらは特定ツールの癖ではなく **Accessibility 設計そのものに起因**し、XCUITest・Maestro・agent-device で
   一貫して再現する＝ **アクセシビリティ設計は、人間（VoiceOver）だけでなくテスト・自動操作・AI Agent
   共通の「機械可読インターフェース」になっている**。
7. 本表の「agent-device」列は **ツリー型 AI Agent**。スクショを見て座標を叩く **ビジョン型**は別モダリティで、
   装飾UI を座標で押せる利点がある反面、座標の脆さ・意味理解の弱さがある（`docs/ai-agent-scope.md`）。
   どちらに対しても **意味情報を持った素直な UI** が結局強い。

## 関連ドキュメント

- `docs/xcuitest-baseline.md` — 基準値・Toggle の詳細
- `docs/identifier-label.md` — identifier/label・親子の伝播・`.contain` 回避策
- `docs/grouping.md` — `.combine`/`.contain`/`.ignore`
- `docs/decorative.md` — 装飾UI / カスタム描画
- `docs/swiftui-vs-uikit.md` — SwiftUI/UIKit 差分
- `docs/voiceover.md` — VoiceOver の実測（公式監査＋読み上げ内容）
- `docs/maestro.md` / `docs/agent-device.md` — ツール別の視点
- `docs/trees/` — 各画面のアクセシビリティツリー実測
