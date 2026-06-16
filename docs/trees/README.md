# アクセシビリティツリー スナップショット

SwiftUIApp / UIKitApp の各画面状態における「機械から見たアクセシビリティツリー」
（要素タイプ / identifier / label / value / frame）を `app.debugDescription` で採取したもの。
Accessibility Inspector（GUI）と同等の情報を、OSS なし・1 コマンドで再現・差分管理できる形で残す。
SwiftUI / UIKit 差分の比較は `docs/swiftui-vs-uikit.md` を参照。

| ファイル | 画面状態 |
| -- | -- |
| `swiftui-*.txt` / `uikit-*.txt` | フレームワーク別のプレフィックス |
| `*-basics-top.txt` | 基本要素画面（起動直後） |
| `*-basics-bottom.txt` | 基本要素画面（下までスクロール） |
| `*-modal.txt` | モーダル表示中 |
| `*-alert.txt` | アラート表示中 |
| `*-about.txt` | About タブ |
| `*-idlabel.txt` | ID/Label 検証画面（SwiftUI / UIKit 両方） |

## 再生成

```sh
scripts/dump-accessibility-trees.sh
# デスティネーションの変更:
scripts/dump-accessibility-trees.sh 'platform=iOS Simulator,name=iPhone 15,OS=17.5'
```

採取ロジックは `SwiftUIAppUITests/AccessibilityTreeSnapshotTests.swift` と
`UIKitAppUITests/UIKitAccessibilityTreeSnapshotTests.swift`。専用スキーム
（`SwiftUIApp-Trees` / `UIKitApp-Trees`）で実行する。iOS の UI テストはシミュレータ側
サンドボックスで動くためリポジトリへ直接書き込めない。そのためテストはツリーをマーカー付きで
標準出力し、スクリプト側が各ファイルに切り出している。
