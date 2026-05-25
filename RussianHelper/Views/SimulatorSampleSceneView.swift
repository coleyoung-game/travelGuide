import SwiftUI

struct SimulatorSampleSceneView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.14, blue: 0.16),
                    Color(red: 0.30, green: 0.27, blue: 0.22),
                    Color(red: 0.15, green: 0.18, blue: 0.21)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 36) {
                Text("Москва")
                    .font(.system(size: 54, weight: .heavy, design: .serif))
                    .foregroundStyle(.white)
                    .padding(.top, 130)

                Text("Завтрак")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.98, green: 0.88, blue: 0.56))

                Spacer()

                HStack {
                    Spacer()
                    Text("Выход")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
                        .padding(.trailing, 52)
                        .padding(.bottom, 170)
                }
            }
        }
    }
}
