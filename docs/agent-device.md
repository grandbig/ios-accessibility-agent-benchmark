# agent-device（AI Agent）視点の検証

Issue #1 の検証ツール表の4つ目。AI Agent がモバイル UI を操作するための CLI
[agent-device](https://www.npmjs.com/package/agent-device)（v0.17.5）で、AI Agent が
「同じ画面をどう見て、どう操作するか」を XCUITest / Maestro と比較した。

> agent-device は LLM そのものではなく、**AI Agent のためのセンサ（snapshot）＋アクチュエータ（click/find）層**。
> LLM はこの snapshot（意味的ツリー）を見て click を選ぶ。本検証は API キー不要でこの層を直接動かしている。
>
> なお agent-device の snapshot は **ツリー型（accessibility-tree）** のモダリティ。スクショを見て座標を叩く
> **ビジョン型**との違い（どちらが何に効くか）は `docs/ai-agent-scope.md` を参照。

- 実行環境: agent-device 0.17.5 / iPhone SE (3rd generation) iOS 26.0 Simulator
- セッション: `agent-device open --session sim --platform ios --device "iPhone SE (3rd generation)" com.grandbig.a11ybench.swiftui`

## AI Agent が見るツリー（snapshot）

`agent-device snapshot` は **`@ref [role] "label"`** 形式の意味的ツリーを返す。XCUITest の
debugDescription より抽象度が高く、ロール（button / switch / text / cell …）とラベルで構成される。

```
@e24 [cell] "タップ回数: 0"
  @e26 [other] "タップ回数: 0"
    @e27 [button] "タップ回数: 0"
@e28 [cell] "トグル"
  @e30 [other] "トグル"
    @e31 [switch] "トグル"          ← 行全体に広がる外側 switch
      @e32 [text] "トグル"
      @e33 [switch] "0"             ← 実コントロール位置の内側 switch（値を持つ）
```

## クロスツール比較（XCUITest / Maestro / agent-device）

| 検証 | XCUITest | Maestro | agent-device | 一致 |
| -- | -- | -- | -- | :--: |
| Toggle を「ラベル付き switch」中央でタップ | 切替えず | 切替えず | `click @e31`(188,356) で**切替えず** | ✅ |
| Toggle の実コントロールをタップ | 右端 point で可 | 右端 point で可 | `click @e33`(314,356) で**切替成功** | ✅ |
| 装飾: カスタム描画/Gesture(a11yなし) | Other（button でない） | （同左） | `[other] "deco.canvas"`（button でない） | ✅ |
| 装飾: a11y 補完版 | button・操作可 | — | `[button] "送信"`・操作可 | ✅ |
| 装飾: Blur/Glass の上の Button | button 検出 | — | `[button] "ブラーの上"` 検出 | ✅ |

→ **AI Agent から見ても、これまでの結論はそのまま成立**する。「ラベル付き Toggle の中央タップが外れる」
「カスタム描画/Gesture は意味情報がないと操作対象と認識されない」「装飾は検出に影響しない」は
ツールを問わず再現する＝ **Accessibility 設計そのものに起因する**。

## agent-device 視点ならではの観察

### 1. Toggle は内側コントロール（@e33）を選べば操作できる
agent-device は行全体の `@e31 [switch]`（中央 188 = 余白で外す）の中に、実コントロール位置の
`@e33 [switch] "0"`（314 = 右端）を入れ子で公開する。AI が内側 @e33 を選べば切り替えに成功する。
ツリー型ツールの中では「逃げ道」が見えている点が XCUITest/Maestro の素朴な id タップと異なる。

### 2. identifier の上書き（case3）は label 駆動の AI には影響しない
ID/Label 画面で AI が見るのは **ラベル**：

```
@e15 [button] "子ボタン1"
@e21 [button] "子ボタン3"     ← id(idlabel.case3.child) は親に上書きされ壊れているが、ラベルは見える
@e25 [button] "idlabel.case5.noLabelButton"   ← ラベルなし → identifier が名前として露出
```

- `case3`：agent-device は id でも label でも検索できる（`find <locator>`）が、実測すると
  **id 検索も上書きの影響を受ける**：

  ```
  find "子ボタン3"            → "子ボタン3"               （label 検索：成功）
  find "idlabel.case1.child"  → "子ボタン1"               （id 検索：id が生きている case1 は成功）
  find "idlabel.case3.child"  → did not match any element （id 検索：親に上書きされ失敗）
  find "idlabel.case3.parent" → "親"                       （上書き後の親 id は成功）
  ```

  → 「親 identifier の上書き」は **id ベースの検出を XCUITest・Maestro・agent-device の3ツールすべてで壊す**。
  AI Agent が実際には影響を受けにくいのは、agent-device が **ラベル/ロール中心のツリーを見て label で操作する**
  のが基本だからであって、「id でも問題ない」からではない。**id 駆動と label 駆動で“効く問題”が違う**
  （id 上書き → id 駆動が全滅 / ラベルなし → label 駆動で id が露出）。
- `case5`（ラベルなし図形ボタン）：AI が見る名前は **`idlabel.case5.noLabelButton`**（identifier がそのまま露出）。
  人間的に意味をなさず、`accessibilityLabel` の重要性が AI 視点でも裏付けられる。

### 3. フローティングタブバーに隠れる要素は `[covered]`
画面下部の要素（例: `@e27 [button] "子ボタン6" [covered]`、`[button] "ブラーの上" [covered]`）に
`[covered]` が付く。iOS 26 のフローティングタブバーの重なりは、AI Agent から見ても操作の障害になりうる
（Maestro で `centerElement` が必要だったのと同じ問題）。

## まとめ

- AI Agent（agent-device）が見るのは **ロール＋ラベルの意味的ツリー**。本ベンチマークの結論
  （Toggle 中央タップ・装飾UI・装飾は無害）は AI Agent でも一致した。
- 一方、**id 駆動と label 駆動で「効く問題」が異なる**：identifier の上書きは
  **id 駆動（XCUITest/Maestro/agent-device いずれの id 検索でも）を壊す**が、label 駆動には効かない。
  逆に「ラベルなし」は label 駆動で id が露出して効く。agent-device は両方の locator を持つが、
  既定の操作は label/ロール中心。
- 設計の含意は一貫している：**操作対象には role（trait）と意味のある label を与える**。
  そうすれば id 駆動・label 駆動のどちらの自動化／AI からも、安定して検出・操作できる。

## 再現コマンド

```sh
export PATH="$PATH:$(npm root -g)/../bin"   # agent-device が PATH にない場合
agent-device open --session sim --platform ios --device "iPhone SE (3rd generation)" com.grandbig.a11ybench.swiftui
agent-device --session sim snapshot                 # AI が見るツリー
agent-device --session sim click @e33               # ref を指定して操作（ref は snapshot 毎に変わる）
agent-device --session sim find "子ボタン3" get      # ラベルで検出
agent-device --session sim close
```
