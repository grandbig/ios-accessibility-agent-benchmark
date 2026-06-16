# ios-accessibility-agent-benchmark

同じ UI を SwiftUI / UIKit で実装し、Accessibility 設計が
VoiceOver・XCUITest・Maestro・agent-device（AI Agent）の認識・自動操作に
どう影響するかを検証するベンチマーク。詳細な背景・検証計画は Issue #1 を参照。

## 主な成果（サマリ）

検証カバレッジ：

| 観点 | SwiftUI | UIKit |
| -- | :--: | :--: |
| 基本要素（基準値） | ✅ | ✅ |
| identifier / label の付け方 | ✅ | ✅ |
| grouping（`accessibilityElement(children:)`） | ✅ | ✅ |
| 装飾UI（Canvas / Gesture / Blur / Glass） | ✅ | ✅ |

| 検証ツール | Accessibility Inspector 相当 | XCUITest | Maestro | agent-device |
| -- | :--: | :--: | :--: | :--: |
| 状態 | ✅ | ✅ | ✅ | ✅ |

主な知見：

- **操作対象には「意味のある label」＋「一意な identifier」＋「正しい role(trait)」**を与えるのが最安定
  （id駆動・label駆動・VoiceOver・AI のすべてに効く）。
- **親コンテナに `accessibilityIdentifier` を付けると子に伝播・上書きされる（SwiftUI 特有）**。
  id ベースの検出が XCUITest / Maestro / agent-device すべてで壊れる。`.contain` 併用で回避できる（UIKit は伝播しない）。
- **ラベル付き `Toggle` は中央タップが外れる（SwiftUI）**。フレームが行幅に広がるため。UIKit の `UISwitch` は問題なし。
- **grouping の `.combine` / `.ignore` は VoiceOver 向きだが自動操作で子要素が埋もれる**。`.contain` なら両立。
- **「タップできる見た目」と「機械が操作対象と理解する構造」は別**。Canvas / Gesture だけの UI は
  `accessibilityLabel` + `.isButton` がないと操作対象と認識されない。一方 **Blur / Glass 装飾自体は検出に無害**。
- これらは特定ツールの癖ではなく **Accessibility 設計そのものに起因**し、4ツールで一貫して再現する。

→ 総合比較表（◎○△×）は **[`docs/summary.md`](docs/summary.md)** を参照。

## 構成

| ターゲット | 説明 |
| -- | -- |
| `SwiftUIApp` | SwiftUI 実装。bundle id: `com.grandbig.a11ybench.swiftui` |
| `UIKitApp` | UIKit 実装（SwiftUI と同一 UI・同一 identifier）。bundle id: `com.grandbig.a11ybench.uikit` |
| `SwiftUIAppUITests` / `UIKitAppUITests` | 各アプリの基準値 XCUITest |

検証ドキュメント:
- **`docs/summary.md` — 総合比較表（UI設計 × VoiceOver/XCUITest/Maestro/agent-device の ◎○△×）**
- `docs/xcuitest-baseline.md` — 基準値（基本要素の検出/操作）と Toggle の知見
- `docs/swiftui-vs-uikit.md` — 同一 UI の SwiftUI / UIKit 差分
- `docs/identifier-label.md` — identifier/label の付け方の検証（親子の identifier 干渉ほか）
- `docs/grouping.md` — `accessibilityElement(children:)`（combine/contain/ignore）と VoiceOver↔自動操作のトレードオフ
- `docs/decorative.md` — 装飾UI / カスタム描画（Canvas/Gesture/Blur/Glass）と「見た目のボタン≠機械が理解する構造」
- `docs/maestro.md` — Maestro（実E2Eツール）視点と XCUITest とのクロスツール比較（`maestro/` にフロー）
- `docs/agent-device.md` — agent-device（AI Agent）視点と、id駆動 vs label駆動で効く問題の違い

`.xcodeproj` は [XcodeGen](https://github.com/yonaskolb/XcodeGen) で `project.yml` から生成する（git 管理対象外）。

## セットアップ

```sh
brew install xcodegen   # 未導入の場合
xcodegen generate       # AccessibilityBenchmark.xcodeproj を生成
open AccessibilityBenchmark.xcodeproj
```

## ビルド（CLI）

```sh
xcodebuild -project AccessibilityBenchmark.xcodeproj \
  -scheme SwiftUIApp \
  -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation)' \
  build
```

## 検証対象 UI

「基本要素」の基準値画面を SwiftUI / UIKit の両方で実装済み（同一 UI・同一 identifier）。
Text / Button / Toggle / TextField / SecureField / List item / Tab /
Modal / Alert / ScrollView 内の要素を含む。操作対象には
`<screen>.<element>` 命名規約で `accessibilityIdentifier` を付与している。

## アクセシビリティツリーの採取

```sh
scripts/dump-accessibility-trees.sh   # docs/trees/{swiftui,uikit}-*.txt を生成
```
