import Foundation
import UIKit

// MARK: - LLMService Protocol
//
// TODO: MLX Swift 통합 시 아래 MockLLMService를 교체
// 1. Xcode → File → Add Package Dependencies
//    https://github.com/ml-explore/mlx-swift-examples  (MLXVLM, MLXLMCommon)
// 2. MLXLLMService 구현:
//
//   import MLXVLM
//   import MLXLMCommon
//
//   final class MLXLLMService: LLMService {
//       private var container: ModelContainer?
//
//       func load() async throws {
//           let config = ModelConfiguration(
//               id: "mlx-community/Qwen3-VL-4B-Instruct-4bit"
//           )
//           container = try await VLMModelFactory.shared.loadContainer(
//               configuration: config
//           )
//       }
//
//       func generate(messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
//           AsyncThrowingStream { continuation in
//               Task {
//                   try await container?.perform { context in
//                       let input = try await context.processor.prepare(
//                           input: UserInput(messages: messages.toMLXInput())
//                       )
//                       let stream = try generate(
//                           input: input, parameters: .init(), context: context
//                       )
//                       for await part in stream {
//                           continuation.yield(part.chunk ?? "")
//                       }
//                       continuation.finish()
//                   }
//               }
//           }
//       }
//   }

protocol LLMService: AnyObject {
    func generate(messages: [ChatMessage]) -> AsyncThrowingStream<String, Error>
}

// MARK: - Mock Implementation (placeholder)

final class MockLLMService: LLMService {

    func generate(messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        let hasImage = messages.contains { $0.attachedImage != nil }
        let lastText  = messages.last?.content.lowercased() ?? ""

        let response: String
        if hasImage {
            response = """
            📸 이미지를 분석하겠습니다.

            **Qwen3-VL 4B 모델이 통합되면** 다음 작업을 수행할 수 있습니다.

            • 메뉴판 / 간판 텍스트 인식 및 번역
            • 사진 속 물체 / 장소 설명
            • 이미지 기반 질문 답변 (멀티턴 지원)

            현재 연동 대기 중:
            `mlx-community/Qwen3-VL-4B-Instruct-4bit` (~2.5 GB)

            위 이미지에 대해 추가 질문이 있으면 계속 물어보세요!
            """
        } else if lastText.contains("카자흐") || lastText.contains("알마티") || lastText.contains("누르술탄") {
            response = """
            🇰🇿 카자흐스탄 여행 관련 질문이군요!

            **모델 준비 완료 후** 다음을 도와드릴 수 있습니다.

            1. **러시아어 / 카자흐어 번역** — 실시간 텍스트·음성 번역
            2. **현지 음식 추천** — 베시바르막, 쿠이르닥 등
            3. **관광지 안내** — 알마티, 누르술탄 주요 명소
            4. **교통 정보** — 지하철, 택시(Yandex.Taxi) 이용법
            5. **메뉴판 사진 분석** — 카메라로 찍으면 자동 번역

            카메라 번역 기능도 함께 활용해보세요! 📷
            """
        } else if lastText.contains("안녕") || lastText.contains("hello") || lastText.isEmpty {
            response = """
            안녕하세요! 👋 저는 **Russian Helper AI**입니다.

            현재 **Qwen3-VL 4B** 모델 통합을 준비 중입니다.
            MLX Swift 패키지가 추가되면 완전한 AI 대화 기능을 제공합니다.

            지금도 다음 기능은 사용 가능합니다.
            • 📷 **카메라 번역** — 러시아어 실시간 인식·번역

            카자흐스탄 여행, 러시아어 학습, 이미지 분석 등 무엇이든 물어보세요!
            """
        } else {
            response = """
            질문을 받았습니다.

            **현재 상태**: Qwen3-VL 4B 모델 연동 준비 중 🔧

            실제 모델이 연동되면:
            • 텍스트 기반 멀티턴 대화
            • 이미지 첨부 후 연속 질문
            • 러시아어·카자흐어·한국어 지원

            SPM 패키지 추가 후 `MockLLMService` → `MLXLLMService`로 교체하면 완성입니다.
            """
        }

        return AsyncThrowingStream { continuation in
            Task {
                for char in response {
                    try? await Task.sleep(nanoseconds: 11_000_000)
                    continuation.yield(String(char))
                }
                continuation.finish()
            }
        }
    }
}
