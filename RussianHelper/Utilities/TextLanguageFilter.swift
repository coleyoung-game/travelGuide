import Foundation
import NaturalLanguage

enum TextLanguageFilter {
    static func normalized(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .lowercased()
    }

    static func cyrillicRatio(in text: String) -> Double {
        let letters = text.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        guard !letters.isEmpty else { return 0 }

        let cyrillicCount = letters.filter { scalar in
            switch scalar.value {
            case 0x0400...0x052F, 0x2DE0...0x2DFF, 0xA640...0xA69F:
                true
            default:
                false
            }
        }.count

        return Double(cyrillicCount) / Double(letters.count)
    }

    static func isLikelyRussian(_ text: String, minimumCyrillicRatio: Double = 0.35) -> Bool {
        let normalizedText = normalized(text)
        guard normalizedText.count >= 2 else { return false }

        let ratio = cyrillicRatio(in: normalizedText)
        guard ratio >= minimumCyrillicRatio else { return false }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(normalizedText)

        if recognizer.dominantLanguage == .russian {
            return true
        }

        // Very short labels, prices, and menu headings are often too sparse for NL detection.
        return ratio >= 0.65
    }
}
