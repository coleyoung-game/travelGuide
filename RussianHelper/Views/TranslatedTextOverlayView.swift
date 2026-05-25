import SwiftUI

struct TranslatedTextOverlayView: View {
    let regions: [TranslatedTextRegion]
    let sourceAspectRatio: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let mapper = OverlayGeometryMapper(
                sourceAspectRatio: sourceAspectRatio,
                destinationSize: geometry.size
            )

            ZStack(alignment: .topLeading) {
                ForEach(regions) { region in
                    let rect = mapper.viewRect(for: region.normalizedRect)
                    if rect.width > 8, rect.height > 8 {
                        translatedPatch(region: region, rect: rect, mapper: mapper)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func translatedPatch(
        region: TranslatedTextRegion,
        rect: CGRect,
        mapper: OverlayGeometryMapper
    ) -> some View {
        Text(region.translatedText)
            .font(.system(size: mapper.fontSize(for: rect, text: region.translatedText), weight: .bold))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .minimumScaleFactor(0.35)
            .shadow(color: .black.opacity(0.55), radius: 2, x: 0, y: 1)
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .frame(width: max(rect.width, 42), height: max(rect.height, 24))
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(.white.opacity(0.25), lineWidth: 1)
            }
            .position(x: rect.midX, y: rect.midY)
    }
}
