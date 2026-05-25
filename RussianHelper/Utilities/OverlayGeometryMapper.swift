import CoreGraphics
import Foundation

struct OverlayGeometryMapper {
    let sourceAspectRatio: CGFloat
    let destinationSize: CGSize

    init(sourceAspectRatio: CGFloat, destinationSize: CGSize) {
        self.sourceAspectRatio = max(sourceAspectRatio, 0.01)
        self.destinationSize = destinationSize
    }

    func viewRect(for normalizedRect: CGRect) -> CGRect {
        let fitted = aspectFillSourceRect()
        let x = fitted.minX + normalizedRect.minX * fitted.width
        let y = fitted.minY + (1 - normalizedRect.maxY) * fitted.height
        let width = normalizedRect.width * fitted.width
        let height = normalizedRect.height * fitted.height

        return CGRect(x: x, y: y, width: width, height: height)
            .intersection(CGRect(origin: .zero, size: destinationSize))
    }

    func fontSize(for rect: CGRect, text: String) -> CGFloat {
        let base = max(13, min(rect.height * 0.46, rect.width / CGFloat(max(text.count, 1)) * 1.7))
        return min(base, 34)
    }

    private func aspectFillSourceRect() -> CGRect {
        guard destinationSize.width > 0, destinationSize.height > 0 else {
            return .zero
        }

        let destinationAspect = destinationSize.width / destinationSize.height
        if sourceAspectRatio > destinationAspect {
            let height = destinationSize.height
            let width = height * sourceAspectRatio
            return CGRect(x: (destinationSize.width - width) / 2, y: 0, width: width, height: height)
        } else {
            let width = destinationSize.width
            let height = width / sourceAspectRatio
            return CGRect(x: 0, y: (destinationSize.height - height) / 2, width: width, height: height)
        }
    }
}
