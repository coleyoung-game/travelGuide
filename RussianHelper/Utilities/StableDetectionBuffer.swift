import Foundation

struct StableDetectionBuffer {
    private struct Entry {
        var region: DetectedTextRegion
        var hits: Int
        var lastFrameID: Int
    }

    private var entries: [String: Entry] = [:]
    var requiredHits = 2
    var maxFrameGap = 5

    mutating func update(with regions: [DetectedTextRegion]) -> [DetectedTextRegion] {
        guard let newestFrame = regions.map(\.frameID).max() else {
            return []
        }

        entries = entries.filter { _, entry in
            newestFrame - entry.lastFrameID <= maxFrameGap
        }

        for region in regions {
            if var entry = entries[region.normalizedSourceText] {
                entry.region = region
                entry.hits += 1
                entry.lastFrameID = region.frameID
                entries[region.normalizedSourceText] = entry
            } else {
                entries[region.normalizedSourceText] = Entry(region: region, hits: 1, lastFrameID: region.frameID)
            }
        }

        return entries.values
            .filter { $0.hits >= requiredHits }
            .map(\.region)
            .sorted { $0.normalizedRect.minY > $1.normalizedRect.minY }
    }
}
