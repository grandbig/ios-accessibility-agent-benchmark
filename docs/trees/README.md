# アクセシビリティツリー スナップショット

SwiftUIApp の各画面状態における「機械から見たアクセシビリティツリー」
（要素タイプ / identifier / label / value / frame）を `app.debugDescription` で採取したもの。
Accessibility Inspector（GUI）と同等の情報を、OSS なし・1 コマンドで再現・差分管理できる形で残す。

| ファイル | 画面状態 |
| -- | -- |
| `basics-top.txt` | 基本要素画面（起動直後） |
| `basics-bottom.txt` | 基本要素画面（下までスクロール） |
| `modal.txt` | モーダル（sheet）表示中 |
| `alert.txt` | アラート表示中 |
| `about.txt` | About タブ |

## 再生成

```sh
scripts/dump-accessibility-trees.sh
# デスティネーションの変更:
scripts/dump-accessibility-trees.sh 'platform=iOS Simulator,name=iPhone 15,OS=17.5'
```

採取ロジックは `SwiftUIAppUITests/AccessibilityTreeSnapshotTests.swift`。
iOS の UI テストはシミュレータ側サンドボックスで動くためリポジトリへ直接書き込めない。
そのためテストはツリーをマーカー付きで標準出力し、スクリプト側が各ファイルに切り出している。
