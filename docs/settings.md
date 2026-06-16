# 実例: 設定画面（Slider / Stepper / Picker / NavigationLink / 複数 Toggle）

Issue #2 の「実アプリ寄せのサンプル画面」。基本要素の合成画面では現れなかった UI 部品を、
現実的な「設定」画面の文脈でまとめて検証する。基本要素で見つけた知見（Toggle 中央タップ問題など）が
リアルな画面でも再現することを確認しつつ、新しい要素タイプの自動操作からの見え方を実測する。

- 対象画面: `SwiftUIApp/SettingsView.swift`（About の「実例」→ NavigationLink で開く）
- 検証テスト: `SwiftUIAppUITests/SettingsUITests.swift`（全 pass）
- ツリー: `docs/trees/swiftui-settings.txt`
- 実行環境: iPhone SE (3rd generation) / iOS 26.0 Simulator / Xcode 26.4.1

> タブ上限（iPhone は5タブで6つ目が「More」送り）を超えないよう、設定画面は新規タブにせず
> About 画面の「実例」セクションから `NavigationLink` で開く構成にしている。

## 要素タイプ別の見え方（実測）

| 部品 | XCUITest 要素タイプ | label / 操作 | 所感 |
| -- | -- | -- | -- |
| `Toggle`（push / email） | `switch` | 中央 `.tap()` で**切り替わらない** / 右端 point で切替 | 基本要素と同じ問題が**実設定でも再現** |
| `Slider`（fontSize） | `slider` | `adjust(toNormalizedSliderPosition:)` で操作可 | 素直に adjustable |
| `Stepper`（lineSpacing） | `stepper` ＋ **子の2 `button`** | 増減は `…-Increment` / `…-Decrement` | **下記の知見** |
| `Picker`（theme・menu） | `button` | label = 「テーマ, システム」（ラベル＋現在値） | タップでメニュー展開 |
| `NavigationLink`（account） | `button` | タップで詳細へ push | — |
| `Button`（clearCache） | `button` | タップで動作 | — |

## 知見: Stepper の「タップできる実体」は Increment / Decrement の2ボタン

`Stepper(...).accessibilityIdentifier("settings.lineSpacing")` を付けると、ツリー上では素の id は
**`Stepper` 要素**になる（`button` ではない）。実際にタップで増減する操作要素は、その子の**2つのボタン**に
分かれ、それぞれ **`settings.lineSpacing-Increment` / `settings.lineSpacing-Decrement`** という
suffix 付き id を持つ（label は「行間: 2, Increment」等）。実測ツリー（`docs/trees/swiftui-settings.txt`）:

```
Stepper, identifier: 'settings.lineSpacing', label: '行間: 2', value: 2
  Button, identifier: 'settings.lineSpacing-Decrement', label: '行間: 2, Decrement'
  Button, identifier: 'settings.lineSpacing-Increment', label: '行間: 2, Increment'
```

→ `app.steppers["settings.lineSpacing"]` は当たるが、**`app.buttons["settings.lineSpacing"]` は当たらない**。
「Stepper に id を付けたから（ボタンとして）タップできる」と思っても、素の id を `button` として狙う
セレクタは外れ、増減は suffix 付き id（または label）で操作する必要がある。Toggle のフレーム問題・
親 id の上書きと並ぶ、「id を付けただけでは期待通り操作できない」系の落とし穴。

## 知見: Picker（menu）は「ラベル＋現在値」を持つ button

`settings.theme` は `button` として公開され、ラベルは **「テーマ, システム」**（タイトル＋現在の選択値）。
現在値がラベルに含まれるため、状態確認は label で読めるが、テキストとして値が変わる点はテキスト変更に弱い
（label 駆動の自動化は値変化に追従が要る）。

## まとめ

- **基本要素の合成画面で見つけた Toggle 中央タップ問題は、現実的な設定画面でもそのまま再現**する。
- 新しい部品では **Stepper の id 分割**が実務的な落とし穴。`Slider` は素直、`Picker`/`NavigationLink` は button。
- 設計指針は一貫：操作対象には意味のある label を持たせ、id は要素の実体（Stepper なら増減ボタン）に
  合わせて扱う。「id を付けた＝素の id で操作できる」とは限らない。
