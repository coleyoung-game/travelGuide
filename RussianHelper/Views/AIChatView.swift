import SwiftUI
import PhotosUI

// MARK: - Color Palette (Gemini Dark)

private enum C {
    static let bg      = Color(red: 0.106, green: 0.106, blue: 0.122) // #1B1B1F
    static let sidebar = Color(red: 0.082, green: 0.082, blue: 0.098) // #151519
    static let input   = Color(red: 0.176, green: 0.176, blue: 0.200) // #2D2D33
    static let bubble  = Color(red: 0.212, green: 0.216, blue: 0.243) // #36373E
    static let accent  = Color(red: 0.514, green: 0.647, blue: 0.996) // #83A5FE
    static let dim     = Color.white.opacity(0.50)
    static let divider = Color.white.opacity(0.09)
}

// MARK: - AIChatView

struct AIChatView: View {

    @StateObject private var vm = AIChatViewModel()
    @State private var showSidebar = false
    @State private var photoPickerItem: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .leading) {
            // ── Main ──────────────────────────────────────
            mainContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // ── Dim overlay ───────────────────────────────
            if showSidebar {
                Color.black.opacity(0.48)
                    .ignoresSafeArea()
                    .onTapGesture { closeSidebar() }
            }

            // ── Sidebar ───────────────────────────────────
            if showSidebar {
                ChatSidebarView(
                    vm: vm,
                    onNewChat: { vm.newSession(); closeSidebar() },
                    onSelect:  { id in vm.selectSession(id); closeSidebar() }
                )
                .frame(width: 284)
                .transition(.move(edge: .leading))
                .zIndex(2)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: photoPickerItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let img  = UIImage(data: data) {
                    vm.attachedImage = img
                }
            }
        }
    }

    private func closeSidebar() {
        withAnimation(.spring(response: 0.27, dampingFraction: 0.88)) {
            showSidebar = false
        }
    }

    private func openSidebar() {
        withAnimation(.spring(response: 0.27, dampingFraction: 0.88)) {
            showSidebar = true
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ZStack(alignment: .bottom) {
            C.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                if vm.currentSession == nil {
                    welcomeView
                } else {
                    messagesView
                }
            }

            inputBar
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 14) {
            Button { openSidebar() } label: {
                Image(systemName: "sidebar.left")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.78))
            }

            Spacer()

            Text("AI 대화")
                .font(.headline)
                .foregroundStyle(.white)

            Spacer()

            Button { vm.newSession() } label: {
                Image(systemName: "square.and.pencil")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.78))
            }

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.78))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(C.bg)
    }

    // MARK: - Welcome View

    private var welcomeView: some View {
        VStack {
            Spacer()

            VStack(spacing: 20) {
                // Logo
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [C.accent, Color(red: 0.38, green: 0.56, blue: 1.0)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                    Text("Я")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 10) {
                    Text("어떤 도움이 필요하세요?")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("카자흐스탄 여행 정보, 러시아어 번역,\n이미지 분석 등 무엇이든 물어보세요.")
                        .font(.subheadline)
                        .foregroundStyle(C.dim)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                // Quick-start chips
                HStack(spacing: 10) {
                    QuickChip(icon: "fork.knife", label: "현지 음식 추천") {
                        vm.inputText = "카자흐스탄 전통 음식 추천해줘"
                    }
                    QuickChip(icon: "map", label: "관광지 안내") {
                        vm.inputText = "알마티 꼭 가야 할 관광지 알려줘"
                    }
                }
                HStack(spacing: 10) {
                    QuickChip(icon: "textformat.abc", label: "러시아어 번역") {
                        vm.inputText = "\"감사합니다\"를 러시아어로 알려줘"
                    }
                    QuickChip(icon: "camera", label: "이미지 분석") {
                        // Trigger photo picker
                    }
                }
            }

            Spacer()
            Color.clear.frame(height: 148)
        }
    }

    // MARK: - Messages View

    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(vm.currentMessages) { msg in
                        ChatMessageRow(message: msg)
                            .id(msg.id)
                    }
                    Color.clear
                        .frame(height: 148)
                        .id("__bottom__")
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .onChange(of: vm.currentMessages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("__bottom__")
                }
            }
            .onChange(of: vm.currentMessages.last?.content) { _, _ in
                proxy.scrollTo("__bottom__")
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            // Gradient fade
            LinearGradient(
                colors: [C.bg.opacity(0), C.bg],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 36)
            .allowsHitTesting(false)

            VStack(spacing: 10) {
                // Attached image preview
                if let img = vm.attachedImage {
                    HStack(alignment: .bottom) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    vm.attachedImage = nil
                                    photoPickerItem = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, Color.black.opacity(0.55))
                                }
                                .offset(x: 8, y: -8)
                            }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }

                // Input container
                VStack(spacing: 0) {
                    // Text field + action button
                    HStack(alignment: .bottom, spacing: 10) {
                        TextField("AI에게 물어보기", text: $vm.inputText, axis: .vertical)
                            .font(.body)
                            .foregroundStyle(.white)
                            .tint(C.accent)
                            .lineLimit(1...7)
                            .submitLabel(.send)
                            .onSubmit { if vm.canSend { vm.sendMessage() } }

                        Spacer(minLength: 0)

                        // Right button
                        Group {
                            if vm.isGenerating {
                                Button { vm.stopGeneration() } label: {
                                    Image(systemName: "stop.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(C.accent)
                                }
                            } else if vm.canSend {
                                Button { vm.sendMessage() } label: {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(C.accent)
                                }
                                .transition(.scale.combined(with: .opacity))
                            } else {
                                Image(systemName: "mic")
                                    .font(.title3)
                                    .foregroundStyle(C.dim)
                            }
                        }
                        .frame(width: 34, height: 34)
                        .animation(.spring(response: 0.22), value: vm.canSend)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 6)

                    Rectangle()
                        .fill(C.divider)
                        .frame(height: 1)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)

                    // Toolbar
                    HStack(spacing: 0) {
                        // 파일 업로드
                        PhotosPicker(selection: $photoPickerItem, matching: .images) {
                            InputToolbarButton(icon: "photo.on.rectangle", label: "파일 업로드")
                        }
                        .buttonStyle(.plain)

                        // 카메라 (현재 카메라 번역 앱 진입 가능 — 추후 연결)
                        InputToolbarButton(icon: "camera", label: "카메라")

                        Spacer()

                        // Model badge
                        HStack(spacing: 4) {
                            Text("Qwen3-VL")
                                .font(.caption.weight(.medium))
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundStyle(C.dim)
                        .padding(.trailing, 10)
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 10)
                }
                .background(C.input, in: RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }
}

// MARK: - Chat Sidebar

private struct ChatSidebarView: View {
    @ObservedObject var vm: AIChatViewModel
    var onNewChat: () -> Void
    var onSelect: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [C.accent, Color(red: 0.38, green: 0.56, blue: 1.0)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 34, height: 34)
                    Text("Я")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                }
                Text("Russian Helper")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 18)
            .padding(.top, 22)
            .padding(.bottom, 18)

            // New chat
            Button(action: onNewChat) {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.pencil")
                    Text("새 채팅")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.bottom, 4)

            // Search (visual placeholder)
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                Text("채팅 검색")
            }
            .font(.subheadline)
            .foregroundStyle(C.dim)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)

            Rectangle().fill(C.divider).frame(height: 1).padding(.horizontal, 14)

            // Sessions
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    if !vm.sessions.isEmpty {
                        Text("최근")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(C.dim)
                            .padding(.horizontal, 18)
                            .padding(.top, 14)
                            .padding(.bottom, 4)
                    }
                    ForEach(vm.sessions) { session in
                        sessionRow(session)
                    }

                    if vm.sessions.isEmpty {
                        Text("아직 채팅 기록이 없습니다")
                            .font(.caption)
                            .foregroundStyle(C.dim)
                            .padding(.horizontal, 18)
                            .padding(.top, 20)
                    }
                }
            }

            Spacer()

            Rectangle().fill(C.divider).frame(height: 1).padding(.horizontal, 14)

            navItem(icon: "books.vertical", label: "라이브러리")
            navItem(icon: "diamond", label: "Gems")
                .padding(.bottom, 28)
        }
        .frame(maxHeight: .infinity)
        .background(C.sidebar.ignoresSafeArea())
    }

    private func sessionRow(_ session: ChatSession) -> some View {
        Button { onSelect(session.id) } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(session.title)
                        .font(.subheadline)
                        .lineLimit(1)
                        .foregroundStyle(.white.opacity(0.88))
                    if let last = session.lastMessage {
                        Text(last.content.isEmpty ? "이미지" : last.content)
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundStyle(C.dim)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                vm.selectedSessionID == session.id
                    ? Color.white.opacity(0.10) : Color.clear,
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .contextMenu {
            Button(role: .destructive) { vm.deleteSession(session) } label: {
                Label("삭제", systemImage: "trash")
            }
        }
    }

    private func navItem(icon: String, label: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.subheadline).frame(width: 20)
            Text(label).font(.subheadline)
        }
        .foregroundStyle(C.dim)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }
}

// MARK: - Chat Message Row

private struct ChatMessageRow: View {
    let message: ChatMessage

    var body: some View {
        Group {
            if message.role == .user {
                userRow
            } else {
                assistantRow
            }
        }
        .frame(maxWidth: .infinity,
               alignment: message.role == .user ? .trailing : .leading)
        .padding(.vertical, 6)
    }

    // ── User ──────────────────────────────────
    private var userRow: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if let img = message.attachedImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300, maxHeight: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            if !message.content.isEmpty {
                Text(message.content)
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(C.bubble, in: RoundedRectangle(cornerRadius: 20))
                    .frame(maxWidth: 460, alignment: .trailing)
                    .textSelection(.enabled)
            }
        }
    }

    // ── Assistant ─────────────────────────────
    private var assistantRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Icon + label
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [C.accent, Color(red: 0.38, green: 0.56, blue: 1.0)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                    Text("Я")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }
                Text("Russian Helper AI")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(C.dim)
            }

            // Content
            if message.content.isEmpty && message.isStreaming {
                StreamingDotsView()
                    .padding(.leading, 2)
            } else {
                Text(message.content)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineSpacing(3)
                    .textSelection(.enabled)
            }
        }
    }
}

// MARK: - Streaming Dots

private struct StreamingDotsView: View {
    @State private var go = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.44))
                    .frame(width: 7, height: 7)
                    .scaleEffect(go ? 1.0 : 0.4)
                    .animation(
                        .easeInOut(duration: 0.52)
                            .repeatForever()
                            .delay(Double(i) * 0.17),
                        value: go
                    )
            }
        }
        .onAppear { go = true }
    }
}

// MARK: - Quick Chip

private struct QuickChip: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.footnote)
                Text(label)
                    .font(.footnote.weight(.medium))
            }
            .foregroundStyle(.white.opacity(0.78))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(C.bubble, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Input Toolbar Button

private struct InputToolbarButton: View {
    let icon: String
    let label: String

    var body: some View {
        Label(label, systemImage: icon)
            .font(.subheadline)
            .labelStyle(.titleAndIcon)
            .foregroundStyle(C.dim)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    AIChatView()
}
