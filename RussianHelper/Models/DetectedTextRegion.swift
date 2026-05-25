import CoreGraphics
import Foundation

struct DetectedTextRegion: Identifiable, Equatable, Sendable {
    let id: UUID
    let sourceText: String
    let normalizedSourceText: String
    let confidence: Float
    let normalizedRect: CGRect
    let frameID: Int
    let observedAt: Date

    init(
        id: UUID = UUID(),
        sourceText: String,
        confidence: Float,
        normalizedRect: CGRect,
        frameID: Int,
        observedAt: Date = Date()
    ) {
        self.id = id
        self.sourceText = sourceText
        self.normalizedSourceText = TextLanguageFilter.normalized(sourceText)
        self.confidence = confidence
        self.normalizedRect = normalizedRect
        self.frameID = frameID
        self.observedAt = observedAt
    }
}

struct TranslatedTextRegion: Identifiable, Equatable {
    let id: UUID
    let sourceText: String
    let translatedText: String
    let normalizedRect: CGRect
    let confidence: Float
}
