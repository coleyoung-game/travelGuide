import XCTest
@testable import RussianHelper

final class TextLanguageFilterTests: XCTestCase {
    func testCyrillicRatioDetectsRussianText() {
        XCTAssertGreaterThan(TextLanguageFilter.cyrillicRatio(in: "Москва Завтрак"), 0.9)
    }

    func testCyrillicRatioRejectsKoreanText() {
        XCTAssertEqual(TextLanguageFilter.cyrillicRatio(in: "서울 아침 식사"), 0)
    }

    func testLikelyRussianAllowsShortCyrillicLabels() {
        XCTAssertTrue(TextLanguageFilter.isLikelyRussian("Выход"))
    }
}
