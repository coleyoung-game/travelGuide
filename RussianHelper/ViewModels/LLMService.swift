import Foundation
import UIKit

// MARK: - LLMService Protocol

protocol LLMService: AnyObject, Sendable {
    func generate(messages: [ChatMessage]) -> AsyncThrowingStream<String, Error>
}

// MARK: - MLX Real Implementation

import MLXVLM
import MLXLMCommon

@MainActor
final class MLXLLMService: LLMService, ObservableObject {

    // MARK: Model State

    struct DownloadProgress: Equatable {
        var fraction: Double      // 0.0 – 1.0
        var filesDone: Int        // 완료된 파일 수
        var filesTotal: Int       // 전체 파일 수
        var startedAt: Date       // 다운로드 시작 시각
    }

    enum ModelState: Equatable {
        case notLoaded
        case downloading(DownloadProgress)
        case loading               // weights 로딩/컴파일
        case ready
        case error(String)
    }

    @Published private(set) var modelState: ModelState = .notLoaded

    // MARK: Private

    private var container: ModelContainer?

    // MARK: Cache Check

    /// 모델이 로컬에 이미 다운로드돼 있는지 확인.
    /// Documents/huggingface/models/{id}/ 에 .safetensors 파일이 하나라도 있으면 캐시됨.
    var isModelCached: Bool {
        let dir = VLMRegistry.qwen3VL4BInstruct4Bit.modelDirectory()
        let fm = FileManager.default
        guard fm.fileExists(atPath: dir.path) else { return false }
        let contents = (try? fm.contentsOfDirectory(atPath: dir.path)) ?? []
        return contents.contains { $0.hasSuffix(".safetensors") }
    }

    // MARK: Load

    /// 캐시가 있으면 바로 로드 (다운로드 없음), 없으면 다운로드 후 로드.
    /// 앱 시작 시 자동 호출.
    func loadIfNeeded() {
        guard case .notLoaded = modelState else { return }
        Task { await load() }
    }

    func resetToNotLoaded() {
        container = nil
        modelState = .notLoaded
    }

    func load() async {
        // 이미 로딩 중이거나 준비된 경우 스킵
        switch modelState {
        case .downloading, .loading, .ready: return
        default: break
        }
        guard container == nil else { return }

        let cached = isModelCached

        if cached {
            // 이미 다운로드된 경우: 다운로드 UI 없이 바로 로딩
            modelState = .loading
        } else {
            // 최초 다운로드
            let startTime = Date()
            modelState = .downloading(.init(fraction: 0, filesDone: 0, filesTotal: 0, startedAt: startTime))

            do {
                container = try await VLMModelFactory.shared.loadContainer(
                    configuration: VLMRegistry.qwen3VL4BInstruct4Bit
                ) { [weak self] progress in
                    let fraction   = max(0, min(1, progress.fractionCompleted))
                    let filesDone  = Int(progress.completedUnitCount)
                    let filesTotal = Int(progress.totalUnitCount)
                    Task { @MainActor [weak self] in
                        self?.modelState = .downloading(.init(
                            fraction: fraction,
                            filesDone: filesDone,
                            filesTotal: filesTotal,
                            startedAt: startTime
                        ))
                    }
                }
                modelState = .loading
                try? await Task.sleep(nanoseconds: 200_000_000)
                modelState = .ready
                return
            } catch {
                modelState = .error(error.localizedDescription)
                return
            }
        }

        // 캐시에서 로드 (네트워크 없음, 수 초 소요)
        do {
            container = try await VLMModelFactory.shared.loadContainer(
                configuration: VLMRegistry.qwen3VL4BInstruct4Bit
            )
            modelState = .ready
        } catch {
            modelState = .error(error.localizedDescription)
        }
    }

    // MARK: Generate

    nonisolated func generate(messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard let container = await self.container else {
                    continuation.finish(throwing: LLMError.modelNotLoaded)
                    return
                }

                do {
                    try await container.perform { context in
                        // Build Chat.Message array
                        let chatMessages: [Chat.Message] = messages.map { msg in
                            switch msg.role {
                            case .user:
                                var images: [UserInput.Image] = []
                                if let uiImage = msg.attachedImage,
                                   let ci = CIImage(image: uiImage) {
                                    images.append(.ciImage(ci))
                                }
                                return .user(msg.content, images: images)
                            case .assistant:
                                return .assistant(msg.content)
                            }
                        }

                        let lmInput = try await context.processor.prepare(
                            input: UserInput(chat: chatMessages)
                        )

                        let stream = try MLXLMCommon.generate(
                            input: lmInput,
                            parameters: GenerateParameters(temperature: 0.7),
                            context: context
                        )

                        for await generation in stream {
                            if Task.isCancelled { break }
                            if let chunk = generation.chunk {
                                continuation.yield(chunk)
                            }
                        }
                        continuation.finish()
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - Errors

enum LLMError: LocalizedError {
    case modelNotLoaded

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "모델이 로드되지 않았습니다. 먼저 모델을 다운로드해주세요."
        }
    }
}

// MARK: - Mock Implementation (kept for simulator / unit tests)

final class MockLLMService: LLMService {

    func generate(messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        let hasImage = messages.contains { $0.attachedImage != nil }
        let lastText  = messages.last?.content.lowercased() ?? ""

        let response: String
        if hasImage {
            response = """
            📸 이미지를 분석하겠습니다.

            **이미지 분석 결과:**

            ```
            Qwen3-VL 4B 모델이 이미지를 처리 중입니다.
            ```

            • 메뉴판 / 간판 텍스트 인식 및 번역
            • 사진 속 물체 / 장소 설명
            • 이미지 기반 질문 답변 (멀티턴 지원)

            위 이미지에 대해 추가 질문이 있으면 계속 물어보세요!
            """
        } else if lastText.contains("카자흐") || lastText.contains("알마티") || lastText.contains("누르술탄") {
            response = """
            🇰🇿 카자흐스탄 여행 관련 질문이군요!

            **주요 도움말:**

            1. **러시아어 / 카자흐어 번역** — 실시간 텍스트 번역
            2. **현지 음식 추천** — 베시바르막, 쿠이르닥 등
            3. **관광지 안내** — 알마티, 누르술탄 주요 명소
            4. **교통 정보** — 지하철, 택시(Yandex.Taxi) 이용법
            5. **메뉴판 사진 분석** — 카메라로 찍으면 자동 번역

            카메라 번역 기능도 함께 활용해보세요! 📷
            """
        } else if lastText.contains("안녕") || lastText.contains("hello") || lastText.isEmpty {
            response = """
            안녕하세요! 👋 저는 **Russian Helper AI**입니다.

            다음 기능을 제공합니다:
            • 📷 **카메라 번역** — 러시아어 실시간 인식·번역
            • 💬 **AI 대화** — Qwen3-VL 4B 온디바이스 모델
            • 🖼️ **이미지 분석** — 사진을 첨부해서 질문하세요

            카자흐스탄 여행, 러시아어 학습, 이미지 분석 등 무엇이든 물어보세요!
            """
        } else {
            response = """
            질문을 잘 받았습니다!

            **현재 Mock 모드**로 동작 중입니다. 실제 모델 로딩 후에는:
            - 텍스트 기반 멀티턴 대화
            - 이미지 첨부 후 연속 질문
            - 러시아어·카자흐어·한국어 지원

            다음과 같은 **코드 예시**도 렌더링됩니다:
            ```swift
            let model = Qwen3VL4B()
            let response = try await model.generate(prompt)
            ```

            더 궁금한 것이 있으면 말씀해주세요!
            """
        }

        return AsyncThrowingStream { continuation in
            Task {
                // Simulate word-by-word streaming
                let words = response.split(separator: " ", omittingEmptySubsequences: false)
                for word in words {
                    try? await Task.sleep(nanoseconds: 35_000_000)
                    continuation.yield(String(word) + " ")
                }
                continuation.finish()
            }
        }
    }
}
