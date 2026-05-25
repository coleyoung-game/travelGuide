@preconcurrency import CoreMedia
import CoreGraphics
import Foundation
import ImageIO
@preconcurrency import Vision

actor RussianTextRecognizer {
    private var request: RecognizeTextRequest = {
        var request = RecognizeTextRequest()
        request.recognitionLanguages = [Locale.Language(identifier: "ru")]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = false
        request.minimumTextHeightFraction = 0.015
        return request
    }()

    func recognize(sampleBuffer: CMSampleBuffer, frameID: Int) async -> [DetectedTextRegion] {
        do {
            let observations = try await request.perform(on: sampleBuffer, orientation: .up)
            return observations.compactMap { observation in
                let text = observation.transcript
                guard TextLanguageFilter.isLikelyRussian(text), observation.confidence >= 0.35 else {
                    return nil
                }

                return DetectedTextRegion(
                    sourceText: text,
                    confidence: observation.confidence,
                    normalizedRect: Self.boundingRect(for: observation),
                    frameID: frameID
                )
            }
        } catch {
            return []
        }
    }

    private static func boundingRect(for observation: RecognizedTextObservation) -> CGRect {
        let points = [
            observation.topLeft.cgPoint,
            observation.topRight.cgPoint,
            observation.bottomRight.cgPoint,
            observation.bottomLeft.cgPoint
        ]

        let minX = points.map(\.x).min() ?? 0
        let maxX = points.map(\.x).max() ?? 0
        let minY = points.map(\.y).min() ?? 0
        let maxY = points.map(\.y).max() ?? 0

        return CGRect(
            x: min(max(minX, 0), 1),
            y: min(max(minY, 0), 1),
            width: min(max(maxX - minX, 0), 1),
            height: min(max(maxY - minY, 0), 1)
        )
    }
}
