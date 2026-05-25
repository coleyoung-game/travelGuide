import CoreGraphics
import XCTest
@testable import RussianHelper

final class OverlayGeometryMapperTests: XCTestCase {
    func testVisionLowerLeftRectMapsToTopLeftViewCoordinates() {
        let mapper = OverlayGeometryMapper(
            sourceAspectRatio: 1,
            destinationSize: CGSize(width: 100, height: 100)
        )

        let rect = mapper.viewRect(for: CGRect(x: 0.1, y: 0.7, width: 0.2, height: 0.1))

        XCTAssertEqual(rect.minX, 10, accuracy: 0.001)
        XCTAssertEqual(rect.minY, 20, accuracy: 0.001)
        XCTAssertEqual(rect.width, 20, accuracy: 0.001)
        XCTAssertEqual(rect.height, 10, accuracy: 0.001)
    }

    func testAspectFillClipsOversizedSource() {
        let mapper = OverlayGeometryMapper(
            sourceAspectRatio: 2,
            destinationSize: CGSize(width: 100, height: 100)
        )

        let rect = mapper.viewRect(for: CGRect(x: 0.45, y: 0.45, width: 0.1, height: 0.1))

        XCTAssertEqual(rect.midX, 50, accuracy: 0.001)
        XCTAssertEqual(rect.midY, 50, accuracy: 0.001)
    }
}
