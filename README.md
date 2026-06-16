# ios-accessibility-agent-benchmark

同じ UI を SwiftUI / UIKit で実装し、Accessibility 設計が
VoiceOver・XCUITest・Maestro・agent-device（AI Agent）の認識・自動操作に
どう影響するかを検証するベンチマーク。詳細な背景・検証計画は Issue #1 を参照。

## 構成

| ターゲット | 説明 |
| -- | -- |
| `SwiftUIApp` | SwiftUI 実装。bundle id: `com.grandbig.a11ybench.swiftui` |
| `UIKitApp` | UIKit 実装（SwiftUI と同一 UI・同一 identifier）。bundle id: `com.grandbig.a11ybench.uikit` |
| `SwiftUIAppUITests` / `UIKitAppUITests` | 各アプリの基準値 XCUITest |

検証ドキュメント:
- `docs/xcuitest-baseline.md` — 基準値（基本要素の検出/操作）と Toggle の知見
- `docs/swiftui-vs-uikit.md` — 同一 UI の SwiftUI / UIKit 差分
- `docs/identifier-label.md` — identifier/label の付け方の検証（親子の identifier 干渉ほか）
- `docs/grouping.md` — `accessibilityElement(children:)`（combine/contain/ignore）と VoiceOver↔自動操作のトレードオフ

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
