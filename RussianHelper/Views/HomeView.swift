import SwiftUI

struct HomeView: View {
    @State private var showCameraTranslation = false
    @State private var showAIChat = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerView
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 24)

                    darkBannerCard
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)

                    sectionLabel("기능")
                        .padding(.horizontal, 24)
                        .padding(.bottom, 14)

                    featureCardsRow
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)

                    aiChatCard
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)

                    HStack(alignment: .firstTextBaseline) {
                        sectionLabel("최근 활동")
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 4)

                    Text("아직 활동 기록이 없습니다")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)

                    recentActivityPlaceholder
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                }
            }

            tabBar
        }
        .fullScreenCover(isPresented: $showCameraTranslation) {
            ContentView()
        }
        .fullScreenCover(isPresented: $showAIChat) {
            AIChatView()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(alignment: .center) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(UIColor.systemGray5))
                        .frame(width: 48, height: 48)
                    Text("Я")
                        .font(.headline.bold())
                        .foregroundStyle(Color(UIColor.label))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Welcome to")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Russian Helper")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color(UIColor.label))
                }
            }

            Spacer()

            Button {} label: {
                Image(systemName: "bell")
                    .font(.title3)
                    .foregroundStyle(Color(UIColor.label))
            }
        }
    }

    // MARK: - Dark Banner

    private var darkBannerCard: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color(UIColor.label))
            .frame(height: 80)
            .overlay {
                HStack(spacing: 14) {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundStyle(Color.yellow)
                        .frame(width: 34)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("카메라 번역 시작")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color(UIColor.systemBackground))
                        Text("카메라로 러시아어를 실시간 번역")
                            .font(.caption)
                            .foregroundStyle(Color(UIColor.systemBackground).opacity(0.55))
                    }

                    Spacer()

                    Button { showCameraTranslation = true } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 40, height: 40)
                            Image(systemName: "arrow.right")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.horizontal, 22)
            }
    }

    // MARK: - Section Label

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.title3.weight(.bold))
            .foregroundStyle(Color(UIColor.label))
    }

    // MARK: - Feature Cards Row

    private var featureCardsRow: some View {
        HStack(spacing: 14) {
            cameraFeatureCard
            statsCard
        }
        .frame(height: 168)
    }

    private var cameraFeatureCard: some View {
        Button { showCameraTranslation = true } label: {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(UIColor.systemBackground))
                .overlay {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .top) {
                            Text("카메라\n번역")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color(UIColor.label))
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)
                        }

                        Spacer()

                        HStack(spacing: 10) {
                            ForEach([
                                "camera.fill",
                                "eye.fill",
                                "character.book.closed.fill",
                                "textformat"
                            ], id: \.self) { icon in
                                Image(systemName: icon)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Divider()
                            .padding(.vertical, 8)

                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(UIColor.systemGray5))
                                    .frame(height: 22)
                            }
                        }
                    }
                    .padding(16)
                }
        }
        .buttonStyle(.plain)
    }

    private var statsCard: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color(UIColor.systemBackground))
            .overlay {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Text("번역 현황")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color(UIColor.label))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 16) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("0")
                                .font(.title2.bold())
                                .foregroundStyle(Color(UIColor.label))
                            Text("번역")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("0")
                                .font(.title2.bold())
                                .foregroundStyle(Color(UIColor.label))
                            Text("세션")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    miniLineChart
                        .padding(.bottom, 2)
                }
                .padding(16)
            }
    }

    private var miniLineChart: some View {
        GeometryReader { geo in
            let pts: [CGFloat] = [0.6, 0.8, 0.5, 0.9, 0.4, 0.7, 0.3]
            let w = geo.size.width / CGFloat(pts.count - 1)
            let h = geo.size.height

            ZStack(alignment: .topLeading) {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h * (1 - pts[0])))
                    for i in 1..<pts.count {
                        p.addLine(to: CGPoint(x: CGFloat(i) * w, y: h * (1 - pts[i])))
                    }
                }
                .stroke(Color(UIColor.systemGray3), lineWidth: 1.5)

                Circle()
                    .fill(Color(UIColor.systemGray3))
                    .frame(width: 6, height: 6)
                    .position(
                        x: CGFloat(pts.count - 1) * w,
                        y: h * (1 - pts.last!)
                    )
            }
        }
        .frame(height: 44)
    }

    // MARK: - AI Chat Card

    private var aiChatCard: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color(UIColor.systemBackground))
            .overlay {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Qwen3-VL · Local LLM")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)

                        Text("AI 대화")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color(UIColor.label))

                        Text("이미지 첨부 후 연속 질문,\n러시아어 · 카자흐어 지원")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)

                        Spacer()

                        Button {
                            showAIChat = true
                        } label: {
                            Text("대화 시작")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color(UIColor.systemBackground))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(UIColor.label), in: Capsule())
                        }
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color(UIColor.systemGray6))
                            .frame(width: 88, height: 88)
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Color(UIColor.systemGray2))
                    }
                }
                .padding(20)
            }
            .frame(height: 148)
    }

    // MARK: - Recent Activity Placeholder

    private var recentActivityPlaceholder: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color(UIColor.systemBackground))
            .frame(height: 64)
            .overlay {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color(UIColor.systemGray5))
                            .frame(width: 38, height: 38)
                        Image(systemName: "camera.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("아직 활동 기록이 없습니다")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                        Text("카메라 번역을 시작해보세요")
                            .font(.caption)
                            .foregroundStyle(Color(UIColor.systemGray3))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color(UIColor.systemGray4))
                }
                .padding(.horizontal, 16)
            }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 0) {
                tabBarItem(icon: "house.fill",  label: "홈",   isActive: true)
                tabBarItem(icon: "clock",       label: "활동", isActive: false)
                tabBarItem(icon: "chart.bar",   label: "분석", isActive: false)
            }
            .frame(height: 68)
            .background(Color(UIColor.systemBackground))
        }
    }

    private func tabBarItem(icon: String, label: String, isActive: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(isActive ? Color(UIColor.label) : Color(UIColor.systemGray3))
            Text(label)
                .font(.caption2)
                .foregroundStyle(isActive ? Color(UIColor.label) : Color(UIColor.systemGray3))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
    }
}

#Preview {
    HomeView()
}
