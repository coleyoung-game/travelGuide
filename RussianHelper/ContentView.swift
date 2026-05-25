import SwiftUI
import Translation

struct ContentView: View {
    @StateObject private var viewModel = CameraTranslationViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            #if targetEnvironment(simulator)
            CameraPreviewView(session: viewModel.captureSession, translatedRegions: [])
                .ignoresSafeArea()

            SimulatorSampleSceneView()
                .ignoresSafeArea()
            #else
            CameraPreviewView(session: viewModel.captureSession, translatedRegions: [])
                .ignoresSafeArea()
            #endif

            TranslatedTextOverlayView(
                regions: viewModel.translatedRegions,
                sourceAspectRatio: viewModel.videoAspectRatio
            )
            .ignoresSafeArea()

            VStack {
                HStack(spacing: 10) {
                    // Back to home
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.bordered)
                    .help("홈으로 돌아가기")

                    Label(viewModel.statusText, systemImage: viewModel.statusIconName)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))

                    Spacer()

                    Button {
                        viewModel.prepareLanguagesAgain()
                    } label: {
                        Image(systemName: "arrow.down.message")
                    }
                    .buttonStyle(.borderedProminent)
                    .help("Prepare Russian and Korean language packs")

                    Button {
                        viewModel.toggleCamera()
                    } label: {
                        Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                    }
                    .buttonStyle(.bordered)
                    .help(viewModel.isRunning ? "Pause camera" : "Start camera")
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)

                Spacer()
            }
        }
        .task {
            await viewModel.configure()
        }
        .onDisappear {
            viewModel.stop()
        }
        .translationTask(viewModel.translationConfiguration) { session in
            await viewModel.runTranslationLoop(session)
        }
    }
}
