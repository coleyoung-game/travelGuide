import CoreGraphics
import XCTest
@testable import RussianHelper

final class TranslationCacheTests: XCTestCase {
    func testMissingRegionsSkipsCachedAndPendingTexts() {
        var cache = TranslationCache()
        cache.insert("모스크바", for: TextLanguageFilter.normalized("Москва"))

        let regions = [
            DetectedTextRegion(sourceText: "Москва", confidence: 0.9, normalizedRect: .zero, frameID: 1),
            DetectedTextRegion(sourceText: "Выход", confidence: 0.9, normalizedRect: .zero, frameID: 1),
            DetectedTextRegion(sourceText: "Завтрак", confidence: 0.9, normalizedRect: .zero, frameID: 1)
        ]

        let missing = cache.missingRegions(
            from: regions,
            excluding: [TextLanguageFilter.normalized("Выход")]
        )

        XCTAssertEqual(missing.map(\.sourceText), ["Завтрак"])
    }
}
