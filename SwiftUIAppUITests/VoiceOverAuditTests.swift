import XCTest

/// VoiceOver の実測。Apple 公式の `performAccessibilityAudit` を各画面で実行し、
/// 「要素の説明（accessibilityLabel）が欠落している＝VoiceOver が名前を読めない」要素を計測する。
/// これにより docs/summary.md の VoiceOver 列を推定ではなく実測で裏づける。詳細は docs/voiceover.md。
///
/// 注: Contrast / TextClipped などの監査も走るが、サンプルの配色・レイアウト由来で本テーマ
/// （機械可読性）とは別軸のため、ここでは `.sufficientElementDescription`（説明欠落）に絞って計測する。
final class VoiceOverAuditTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    /// 現在の画面で「説明欠落」要素を数える（監査は失敗させず記録のみ）。
    private func missingDescriptionCount(_ screen: String) throws -> Int {
        var missing = 0
        try app.performAccessibilityAudit { issue in
            if issue.auditType.contains(.sufficientElementDescription) {
                missing += 1
                let label = issue.element?.label ?? ""
                let id = issue.element?.identifier ?? ""
                print("VO-AUDIT[\(screen)] 説明欠落: label='\(label)' id='\(id)'")
            }
            return true // すべて suppress（記録のみ・テストは失敗させない）
        }
        print("VO-AUDIT[\(screen)] 説明欠落 合計=\(missing)")
        return missing
    }

    /// 基本要素：全要素に説明があり、VoiceOver で名前を読める。
    func testBasics_allElementsHaveDescription() throws {
        XCTAssertEqual(try missingDescriptionCount("basics"), 0)
    }

    /// ID/Label：identifier のみでラベルがない case5 が「説明欠落」として検出される。
    func testIdLabel_noLabelButtonIsFlagged() throws {
        app.tabBars.buttons["ID/Label"].tap()
        XCTAssertTrue(app.staticTexts["① 子Buttonのみにidentifier"].waitForExistence(timeout: 3))
        XCTAssertGreaterThanOrEqual(
            try missingDescriptionCount("idlabel"), 1,
            "ラベルなしボタン(case5)が説明欠落として検出されるはず"
        )
    }

    /// Grouping：全要素に説明がある。
    func testGrouping_allElementsHaveDescription() throws {
        app.tabBars.buttons["Grouping"].tap()
        XCTAssertTrue(app.staticTexts["① groupingなし（default）"].waitForExistence(timeout: 3))
        XCTAssertEqual(try missingDescriptionCount("grouping"), 0)
    }

    /// Decorative：accessibility を与えていない Canvas / Gesture の要素が「説明欠落」として検出される。
    func testDecorative_unlabeledCustomUIIsFlagged() throws {
        app.tabBars.buttons["Decorative"].tap()
        XCTAssertTrue(app.staticTexts["① Canvas描画（アクセシビリティなし）"].waitForExistence(timeout: 3))
        XCTAssertGreaterThanOrEqual(
            try missingDescriptionCount("decorative"), 2,
            "a11yなしの Canvas / Gesture が説明欠落として検出されるはず"
        )
    }
}
