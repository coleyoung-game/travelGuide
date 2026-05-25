import CoreGraphics
import XCTest
@testable import RussianHelper

final class StableDetectionBufferTests: XCTestCase {
    func testRequiresRepeatedDetectionBeforeReturningStableRegion() {
        var buffer = StableDetectionBuffer()
        buffer.requiredHits = 2

        let first = buffer.update(with: [
            DetectedTextRegion(sourceText: "Москва", confidence: 0.9, normalizedRect: .zero, frameID: 1)
        ])
        XCTAssertTrue(first.isEmpty)

        let second = buffer.update(with: [
            DetectedTextRegion(sourceText: "Москва", confidence: 0.92, normalizedRect: .zero, frameID: 2)
        ])
        XCTAssertEqual(second.map(\.sourceText), ["Москва"])
    }
}
