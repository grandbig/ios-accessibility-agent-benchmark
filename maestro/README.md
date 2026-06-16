# Maestro フロー

実 E2E ツール（[Maestro](https://maestro.mobile.dev/)）視点での検証フロー。
XCUITest と同じ画面・同じ identifier を、別ツールがどう見る／操作するかを比較する。

| フロー | 内容 |
| -- | -- |
| `basics.yaml` | 基本要素のハッピーパス（Button / Toggle / Modal） |
| `identifier_label.yaml` | identifier の親→子伝播のクロス確認（case3.child は検出不可） |

考察・XCUITest との比較は `docs/maestro.md`。

## 実行

```sh
# シミュレータに SwiftUIApp をインストールしておく
xcodegen generate
xcodebuild -project AccessibilityBenchmark.xcodeproj -scheme SwiftUIApp \
  -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation)' build
# .app を booted シミュレータに install（または Xcode で一度 Run）

# Maestro 実行（booted シミュレータが複数あるときは --device <udid> を指定）
maestro test maestro/basics.yaml
maestro test maestro/identifier_label.yaml

# Maestro が見るツリーの確認
maestro hierarchy
```

> 注意（iOS 26）: フローティングタブバーが画面下部に重なるため、最下部の要素を
> タップするフローでは `scrollUntilVisible` に `centerElement: true` を付け、
> 要素を中央へ寄せてからタップする（タブバーにタップが吸われるのを防ぐ）。
