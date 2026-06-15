# ios-accessibility-agent-benchmark

同じ UI を SwiftUI / UIKit で実装し、Accessibility 設計が
VoiceOver・XCUITest・Maestro・agent-device（AI Agent）の認識・自動操作に
どう影響するかを検証するベンチマーク。詳細な背景・検証計画は Issue #1 を参照。

## 構成

| ターゲット | 説明 |
| -- | -- |
| `SwiftUIApp` | SwiftUI 実装。bundle id: `com.grandbig.a11ybench.swiftui` |
| `UIKitApp` | UIKit 実装（現状はプレースホルダ）。bundle id: `com.grandbig.a11ybench.uikit` |

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

現在は「基本要素」の基準値画面（SwiftUI）を実装済み。
Text / Button / Toggle / TextField / SecureField / List item / Tab /
Modal(sheet) / Alert / ScrollView 内の要素を含む。操作対象には
`<screen>.<element>` 命名規約で `accessibilityIdentifier` を付与している。
