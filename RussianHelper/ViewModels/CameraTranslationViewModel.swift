import AVFoundation
import Foundation
import SwiftUI
import Translation
import Vision

@MainActor
final class CameraTranslationViewModel: ObservableObject {
    @Published var captureSession = AVCaptureSession()
    @Published var translatedRegions: [TranslatedTextRegion] = []
    @Published var statusText = "초기화 중"
    @Published var statusIconName = "camera.viewfinder"
    @Published var isRunning = false
    @Published var videoAspectRatio: CGFloat = 3.0 / 4.0
    @Published var translationConfiguration: TranslationSession.Configuration?

    private var cameraController: CameraSessionController?
    private var stableBuffer = StableDetectionBuffer()
    private var translationCache = TranslationCache()
    private var pendingRegions: [String: DetectedTextRegion] = [:]
    private var pendingKeys = Set<String>()
    private var simulatorTask: Task<Void, Never>?

    func configure() async {
        translationConfiguration = TranslationSession.Configuration(
            source: Locale.Language(identifier: "ru"),
            target: Locale.Language(identifier: "ko")
        )

        guard supportsRussianOCR() else {
            statusText = "러시아어 OCR 미지원"
            statusIconName = "exclamationmark.triangle"
            return
        }

        #if targetEnvironment(simulator)
        statusText = "시뮬레이터 샘플 모드"
        statusIconName = "rectangle.on.rectangle"
        startSimulatorSampleMode()
        #else
        await configureCameraPermission()
        #endif
    }

    nonisolated func runTranslationLoop(_ session: TranslationSession) async {
        do {
            await MainActor.run {
                self.statusText = "언어팩 준비 중"
                self.statusIconName = "arrow.down.circle"
            }
            try await session.prepareTranslation()
            await MainActor.run {
                self.statusText = self.isRunning ? "실시간 번역 중" : "번역 준비 완료"
                self.statusIconName = "text.viewfinder"
            }
        } catch {
            await MainActor.run {
                self.statusText = "언어팩 확인 필요"
                self.statusIconName = "exclamationmark.icloud"
            }
        }

        while !Task.isCancelled {
            let requests = await MainActor.run {
                self.dequeuePendingTranslationRequests(limit: 8)
            }

            if !requests.isEmpty {
                do {
                    let translationRequests = requests.map {
                        TranslationSession.Request(
                            sourceText: $0.value.sourceText,
                            clientIdentifier: $0.key
                        )
                    }
                    let responses = try await session.translations(from: translationRequests)
                    await MainActor.run {
                        self.applyTranslationResponses(responses)
                    }
                } catch {
                    await MainActor.run {
                        self.pendingKeys.subtract(requests.map(\.key))
                        self.statusText = "번역 대기 중"
                        self.statusIconName = "clock.badge.exclamationmark"
                    }
                }
            }

            try? await Task.sleep(for: .milliseconds(250))
        }
    }

    func prepareLanguagesAgain() {
        var configuration = translationConfiguration
        configuration?.invalidate()
        translationConfiguration = configuration
        statusText = "언어팩 재확인"
        statusIconName = "arrow.down.circle"
    }

    func toggleCamera() {
        if isRunning {
            stop()
        } else {
            cameraController?.start()
            isRunning = cameraController != nil
            statusText = isRunning ? "실시간 번역 중" : statusText
            statusIconName = isRunning ? "text.viewfinder" : statusIconName
        }
    }

    func stop() {
        cameraController?.stop()
        simulatorTask?.cancel()
        simulatorTask = nil
        isRunning = false
        statusText = "일시정지"
        statusIconName = "pause.circle"
    }

    private func configureCameraPermission() async {
        let authorization = AVCaptureDevice.authorizationStatus(for: .video)
        let granted: Bool

        switch authorization {
        case .authorized:
            granted = true
        case .notDetermined:
            granted = await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .video) { allowed in
                    continuation.resume(returning: allowed)
                }
            }
        default:
            granted = false
        }

        guard granted else {
            statusText = "카메라 권한 필요"
            statusIconName = "lock"
            return
        }

        do {
            let controller = CameraSessionController(session: captureSession)
            controller.onDetections = { [weak self] regions, aspectRatio in
                Task { @MainActor in
                    self?.videoAspectRatio = aspectRatio
                    self?.ingest(regions)
                }
            }
            try controller.configure()
            cameraController = controller
            controller.start()
            isRunning = true
            statusText = "실시간 번역 중"
            statusIconName = "text.viewfinder"
        } catch {
            statusText = "카메라 설정 실패"
            statusIconName = "exclamationmark.triangle"
        }
    }

    private func supportsRussianOCR() -> Bool {
        let request = RecognizeTextRequest()
        return request.supportedRecognitionLanguages.contains {
            $0.minimalIdentifier == "ru"
        }
    }

    private func ingest(_ regions: [DetectedTextRegion]) {
        let stableRegions = stableBuffer.update(with: regions)
        let missing = translationCache.missingRegions(from: stableRegions, excluding: pendingKeys)

        for region in missing {
            pendingKeys.insert(region.normalizedSourceText)
            pendingRegions[region.normalizedSourceText] = region
        }

        translatedRegions = stableRegions.map { region in
            let translated = translationCache[region.normalizedSourceText] ?? "..."
            return TranslatedTextRegion(
                id: region.id,
                sourceText: region.sourceText,
                translatedText: translated,
                normalizedRect: region.normalizedRect,
                confidence: region.confidence
            )
        }
    }

    private func dequeuePendingTranslationRequests(limit: Int) -> [(key: String, value: DetectedTextRegion)] {
        Array(pendingRegions.prefix(limit))
    }

    private func applyTranslationResponses(_ responses: [TranslationSession.Response]) {
        for response in responses {
            guard let key = response.clientIdentifier else { continue }
            translationCache.insert(response.targetText, for: key)
            pendingRegions[key] = nil
            pendingKeys.remove(key)
        }

        translatedRegions = translatedRegions.map { region in
            let key = TextLanguageFilter.normalized(region.sourceText)
            guard let translated = translationCache[key] else { return region }
            return TranslatedTextRegion(
                id: region.id,
                sourceText: region.sourceText,
                translatedText: translated,
                normalizedRect: region.normalizedRect,
                confidence: region.confidence
            )
        }
    }

    #if targetEnvironment(simulator)
    private func startSimulatorSampleMode() {
        translationCache.insert("모스크바", for: TextLanguageFilter.normalized("Москва"))
        translationCache.insert("아침 식사", for: TextLanguageFilter.normalized("Завтрак"))
        translationCache.insert("출구", for: TextLanguageFilter.normalized("Выход"))

        simulatorTask?.cancel()
        simulatorTask = Task { [weak self] in
            var frameID = 0
            while !Task.isCancelled {
                frameID += 1
                let sample = [
                    DetectedTextRegion(
                        sourceText: "Москва",
                        confidence: 0.98,
                        normalizedRect: CGRect(x: 0.15, y: 0.68, width: 0.34, height: 0.08),
                        frameID: frameID
                    ),
                    DetectedTextRegion(
                        sourceText: "Завтрак",
                        confidence: 0.96,
                        normalizedRect: CGRect(x: 0.18, y: 0.48, width: 0.42, height: 0.07),
                        frameID: frameID
                    ),
                    DetectedTextRegion(
                        sourceText: "Выход",
                        confidence: 0.95,
                        normalizedRect: CGRect(x: 0.56, y: 0.28, width: 0.26, height: 0.06),
                        frameID: frameID
                    )
                ]
                await MainActor.run {
                    self?.ingest(sample)
                    self?.isRunning = true
                }
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }
    #endif
}
