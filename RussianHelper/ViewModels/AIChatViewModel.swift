import SwiftUI

@MainActor
final class AIChatViewModel: ObservableObject {

    // MARK: - Published

    @Published var sessions: [ChatSession] = []
    @Published var selectedSessionID: UUID? = nil
    @Published var inputText: String = ""
    @Published var attachedImage: UIImage? = nil
    @Published var isGenerating: Bool = false

    /// Forwarded from MLXLLMService so views can observe model load progress.
    @Published var modelState: MLXLLMService.ModelState = .notLoaded

    // MARK: - Services

    let mlxService = MLXLLMService()
    private var llm: LLMService { mlxService }
    private var generationTask: Task<Void, Never>?

    // MARK: - Init

    init() {
        // Mirror mlxService.modelState into our own published var
        Task { [weak self] in
            guard let self else { return }
            for await state in self.mlxService.$modelState.values {
                self.modelState = state
            }
        }
    }

    // MARK: - Model Loading

    /// Kick off model download + compilation.
    func loadModel() {
        Task { await mlxService.load() }
    }

    var modelIsReady: Bool {
        if case .ready = modelState { return true }
        return false
    }

    // MARK: - Computed

    var currentSession: ChatSession? {
        sessions.first { $0.id == selectedSessionID }
    }

    var currentMessages: [ChatMessage] {
        currentSession?.messages ?? []
    }

    var canSend: Bool {
        guard modelIsReady else { return false }
        return !inputText.trimmingCharacters(in: .whitespaces).isEmpty || attachedImage != nil
    }

    // MARK: - Session Management

    func newSession() {
        let s = ChatSession()
        sessions.insert(s, at: 0)
        selectedSessionID = s.id
        inputText = ""
        attachedImage = nil
    }

    func selectSession(_ id: UUID) {
        selectedSessionID = id
    }

    func deleteSession(_ session: ChatSession) {
        sessions.removeAll { $0.id == session.id }
        if selectedSessionID == session.id {
            selectedSessionID = sessions.first?.id
        }
    }

    // MARK: - Messaging

    func sendMessage() {
        guard canSend else { return }
        if currentSession == nil { newSession() }

        let msg = ChatMessage(
            role: .user,
            content: inputText,
            attachedImage: attachedImage
        )

        // Auto-title the session from first message
        if let idx = sessionIndex, sessions[idx].messages.isEmpty {
            sessions[idx].title = inputText.isEmpty ? "이미지 분석" : String(inputText.prefix(26))
        }

        append(msg)
        inputText = ""
        attachedImage = nil
        startGeneration()
    }

    func stopGeneration() {
        generationTask?.cancel()
        generationTask = nil
        finalizeAllStreaming()
        isGenerating = false
    }

    // MARK: - Private Helpers

    private var sessionIndex: Int? {
        sessions.firstIndex { $0.id == selectedSessionID }
    }

    private func append(_ msg: ChatMessage) {
        guard let idx = sessionIndex else { return }
        sessions[idx].messages.append(msg)
    }

    private func startGeneration() {
        isGenerating = true
        let placeholder = ChatMessage(role: .assistant, content: "", isStreaming: true)
        let pid = placeholder.id
        append(placeholder)

        // Snapshot messages (excluding the empty placeholder)
        let history = Array(currentMessages.dropLast())

        generationTask = Task {
            let stream = llm.generate(messages: history)
            do {
                for try await token in stream {
                    guard !Task.isCancelled else { break }
                    appendToken(pid, token)
                }
            } catch {
                appendToken(pid, "\n\n*오류: \(error.localizedDescription)*")
            }
            finalizeMessage(pid)
            isGenerating = false
        }
    }

    private func appendToken(_ id: UUID, _ token: String) {
        guard let si = sessionIndex,
              let mi = sessions[si].messages.firstIndex(where: { $0.id == id }) else { return }
        sessions[si].messages[mi].content += token
    }

    private func finalizeMessage(_ id: UUID) {
        guard let si = sessionIndex,
              let mi = sessions[si].messages.firstIndex(where: { $0.id == id }) else { return }
        sessions[si].messages[mi].isStreaming = false
    }

    private func finalizeAllStreaming() {
        guard let si = sessionIndex else { return }
        for i in sessions[si].messages.indices {
            sessions[si].messages[i].isStreaming = false
        }
    }
}
