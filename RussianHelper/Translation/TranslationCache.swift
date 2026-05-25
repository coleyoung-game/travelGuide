import Foundation

struct TranslationCache {
    private var storage: [String: String] = [:]

    var count: Int {
        storage.count
    }

    subscript(normalizedSource: String) -> String? {
        storage[normalizedSource]
    }

    mutating func insert(_ translatedText: String, for normalizedSource: String) {
        storage[normalizedSource] = translatedText
    }

    func missingRegions(from regions: [DetectedTextRegion], excluding pendingKeys: Set<String>) -> [DetectedTextRegion] {
        regions.filter { region in
            storage[region.normalizedSourceText] == nil &&
            !pendingKeys.contains(region.normalizedSourceText)
        }
    }
}
