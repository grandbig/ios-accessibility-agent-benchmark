import XCTest

/// identifier/label の付け方ごとの「XCUITest からの見え方」を固定化する検証テスト。
/// 実測で確認した挙動をアサーションとして残し、回帰ガード兼ドキュメントとする。
/// 詳細な考察は docs/identifier-label.md。
final class IdentifierLabelUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["ID/Label"].tap()
        XCTAssertTrue(app.staticTexts["① 子Buttonのみにidentifier"].waitForExistence(timeout: 5))
    }

    /// ① 子のみ identifier（親は無印）→ 子は自分の identifier で検出できる。
    func testCase1_childIdentifierOnly() {
        let child = app.buttons["idlabel.case1.child"]
        XCTAssertTrue(child.exists)
        XCTAssertEqual(child.label, "子ボタン1")
    }

    /// ② 親View のみ identifier → 親の identifier が子Button に伝播する。
    /// `app.buttons["idlabel.case2.parent"]` がボタンとして解決し、label は子の "子ボタン2"。
    func testCase2_parentIdentifierPropagatesToChild() {
        let viaParentId = app.buttons["idlabel.case2.parent"]
        XCTAssertTrue(viaParentId.exists, "親のidentifierが子Buttonに伝播していない")
        XCTAssertEqual(viaParentId.label, "子ボタン2")
        // ラベルからも引ける
        XCTAssertTrue(app.buttons["子ボタン2"].exists)
    }

    /// ③ 親View + 子Button 両方 identifier → 親の identifier が勝ち、子の identifier は失われる。
    /// これが「親Viewにidentifierがあると子のidentifier検出に影響する」の正体。
    func testCase3_parentIdentifierOverridesChild() {
        XCTAssertTrue(app.buttons["idlabel.case3.parent"].exists, "親idでボタンが検出できるはず")
        XCTAssertFalse(
            app.buttons["idlabel.case3.child"].exists,
            "子のidentifierは親に上書きされ検出できないはず"
        )
        XCTAssertEqual(app.buttons["idlabel.case3.parent"].label, "子ボタン3")
    }

    /// ④ label のみ（identifier なし）→ ラベル文字列で検出できる。
    func testCase4_labelOnly() {
        XCTAssertTrue(app.buttons["子ボタン4"].exists)
    }

    /// ⑤ identifier のみ（ラベルなし図形）→ identifier では検出できるが、
    /// アクセシビリティラベルが空＝VoiceOver では名前を読めない（人間向けに不十分）。
    func testCase5_identifierOnlyButNoLabel() {
        let button = app.buttons["idlabel.case5.noLabelButton"]
        XCTAssertTrue(button.exists, "identifierでは検出できる")
        XCTAssertEqual(button.label, "", "ラベルが空（VoiceOverで名前を読めない）")
    }

    /// ⑥ label + identifier 両方 → identifier でもラベルでも検出でき、名前も読める（最も安定）。
    func testCase6_labelAndIdentifier() {
        let button = app.buttons["idlabel.case6.button"]
        XCTAssertTrue(button.exists)
        XCTAssertEqual(button.label, "子ボタン6")
        XCTAssertTrue(app.buttons["子ボタン6"].exists)
    }
}
