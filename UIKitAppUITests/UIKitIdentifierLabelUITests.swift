import XCTest

/// UIKit 版 identifier/label の付け方の検証。SwiftUI 版（IdentifierLabelUITests）との対比が主眼。
/// UIKit では accessibilityIdentifier は View ごとに独立し、親→子へ伝播・上書きしない。
/// 詳細な考察は docs/identifier-label.md。
final class UIKitIdentifierLabelUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["ID/Label"].tap()
        XCTAssertTrue(app.staticTexts["① 子Buttonのみにidentifier"].waitForExistence(timeout: 5))
    }

    /// ① 子のみ identifier → 子は自分の identifier で検出できる（SwiftUI と同じ）。
    func testCase1_childIdentifierOnly() {
        let child = app.buttons["idlabel.case1.child"]
        XCTAssertTrue(child.exists)
        XCTAssertEqual(child.label, "子ボタン1")
    }

    /// ② 親View のみ identifier → 親の id は子Button に伝播しない（SwiftUI と対照的）。
    /// 子Button は無印のまま（label でのみ検出可）。親 stack は独立した要素として id を持つ。
    func testCase2_parentIdentifierDoesNotPropagate() {
        XCTAssertFalse(
            app.buttons["idlabel.case2.parent"].exists,
            "UIKitでは親のidentifierが子Buttonに伝播しないはず"
        )
        XCTAssertTrue(app.buttons["子ボタン2"].exists, "子Buttonはラベルで検出できる")
        XCTAssertTrue(
            app.otherElements["idlabel.case2.parent"].exists,
            "親(UIStackView)は独立した要素としてidを持つ"
        )
    }

    /// ③ 親View + 子Button 両方 identifier → 子は自分の identifier を保持する（上書きされない）。
    /// SwiftUI では親idで上書きされて子idが消えたのと正反対。
    func testCase3_childKeepsOwnIdentifier() {
        XCTAssertTrue(
            app.buttons["idlabel.case3.child"].exists,
            "UIKitでは子は自分のidentifierを保持するはず"
        )
        XCTAssertFalse(
            app.buttons["idlabel.case3.parent"].exists,
            "親のidentifierは子Buttonに乗らないはず"
        )
        XCTAssertEqual(app.buttons["idlabel.case3.child"].label, "子ボタン3")
    }

    /// ④ label のみ → ラベル文字列で検出できる。
    func testCase4_labelOnly() {
        XCTAssertTrue(app.buttons["子ボタン4"].exists)
    }

    /// ⑤ identifier のみ（ラベルなし図形）→ identifier では検出できるが label は空。
    func testCase5_identifierOnlyButNoLabel() {
        let button = app.buttons["idlabel.case5.noLabelButton"]
        XCTAssertTrue(button.exists, "identifierでは検出できる")
        XCTAssertEqual(button.label, "", "ラベルが空（VoiceOverで名前を読めない）")
    }

    /// ⑥ label + identifier 両方 → identifier でもラベルでも検出できる（最も安定）。
    func testCase6_labelAndIdentifier() {
        let button = app.buttons["idlabel.case6.button"]
        XCTAssertTrue(button.exists)
        XCTAssertEqual(button.label, "子ボタン6")
        XCTAssertTrue(app.buttons["子ボタン6"].exists)
    }
}
