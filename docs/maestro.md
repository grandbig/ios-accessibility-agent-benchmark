# Maestro（実E2Eツール）視点の検証と XCUITest との比較

Issue #1 の検証ツール表の3つ目。実 E2E ツール [Maestro](https://maestro.mobile.dev/) が、
同じ SwiftUIApp をどう見て・どう操作するかを XCUITest と比較した。

- フロー: `maestro/basics.yaml`、`maestro/identifier_label.yaml`（いずれも pass）
- 実行環境: Maestro 2.1.0 / iPhone SE (3rd generation) iOS 26.0 Simulator / Xcode 26.4.1

## Maestro が見るツリー（XCUITest とほぼ同じ情報）

`maestro hierarchy` のノードは、XCUITest の accessibility ツリーと同じ情報を別名で持つ:

| Maestro 属性 | 対応 | 例（Toggle） |
| -- | -- | -- |
| `resource-id` | accessibilityIdentifier | `basics.toggle` |
| `accessibilityText` | accessibilityLabel | `トグル` |
| `value` / `checked` | 値 / オン状態 | `0` / `false` |
| `bounds` | フレーム | `[16,329][359,382]`（幅343） |

→ Maestro も XCUITest と同じく **アクセシビリティツリーに依存**しており、見える情報は本質的に同じ。
Toggle のフレームも同じく幅 343（行全体）で見えている。

## クロスツール比較（同じ結論になったもの）

| 検証 | XCUITest | Maestro | 一致 |
| -- | -- | -- | :--: |
| Toggle を id 中央でタップ | `.tap()` で切り替わらない | `tapOn: id` で `checked:true` にならず**失敗** | ✅ 同じ |
| Toggle を右端 point でタップ | 座標オフセットで切替可 | `tapOn: point` で `checked:true` に**成功** | ✅ 同じ |
| ③ 親+子両方 id の子 id 検出 | `buttons["…case3.child"]` 不在 | `assertNotVisible: id …case3.child` が**成立** | ✅ 同じ |
| ③ 上書きされた親 id | 検出できる | `assertVisible: id …case3.parent` 成立 | ✅ 同じ |

→ **「SwiftUI Toggle の中央タップが外れる」「親 identifier が子を上書きする」は、XCUITest 固有ではなく
ツリー依存ツール全般で再現する**ことが、別ツール Maestro でも裏付けられた。
agent-device のようなツリー型 AI Agent でも同じ問題が起きると見込める。

## Maestro 固有の運用知見

- **要素の選択は `resource-id` / テキストで行い、タップは座標**。そのため Toggle のように
  「要素フレームは広いが実ヒット領域が端にある」ケースでは、id 指定だと中央を叩いて外す
  （XCUITest の `.tap()` と同じ理由）。`point` 指定で回避する。
- **iOS 26 のフローティングタブバー**が画面下部に重なるため、最下部の要素をタップするフローでは
  `scrollUntilVisible` に `centerElement: true` を付けて要素を中央へ寄せないと、
  タップがタブバー（隣のタブ）に吸われて誤遷移する。実際にこの取りこぼしを観測し、修正した。

## まとめ

- Maestro は XCUITest と同じアクセシビリティツリーを別名で見ており、**検出可否の結論は一致**する。
- したがって本ベンチマークで見つけた SwiftUI 特有の落とし穴（Toggle 中央タップ・identifier 伝播）は
  **特定ツールの癖ではなく、Accessibility 設計そのものに起因する**と結論できる。
- 一方、タップ手段（座標ベース）やプラットフォーム UI（iOS 26 タブバー）に由来する
  **ツール固有の運用上の差**も存在する。
