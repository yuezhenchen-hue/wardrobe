import SwiftUI

struct AIAssistantView: View {
    @EnvironmentObject var wardrobeVM: WardrobeViewModel
    @EnvironmentObject var weatherService: WeatherService
    @EnvironmentObject var profileVM: ProfileViewModel
    @StateObject private var aiService = AIAssistantService()

    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messagesList
                quickActionsBar
                inputBar
            }
            .background(AppTheme.warmBackground.ignoresSafeArea())
            .navigationTitle("AI 穿搭助手")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                aiService.updateContext(
                    wardrobe: wardrobeVM.clothingItems,
                    weather: weatherService.currentWeather,
                    profile: profileVM.profile
                )
                if aiService.messages.isEmpty {
                    Task { await aiService.sendMessage("你好") }
                }
            }
        }
    }

    // MARK: - Messages

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(aiService.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    if aiService.isGenerating {
                        typingIndicator
                    }
                }
                .padding()
            }
            .onChange(of: aiService.messages.count) { _, _ in
                if let last = aiService.messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 6, height: 6)
                        .opacity(0.6)
                        .animation(
                            .easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.2),
                            value: aiService.isGenerating
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            Spacer()
        }
    }

    // MARK: - Quick Actions

    private var quickActionsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(QuickAction.allCases) { action in
                    Button {
                        Task { await aiService.sendQuickAction(action) }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: action.icon)
                                .font(.caption)
                            Text(action.rawValue)
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppTheme.primaryColor.opacity(0.1))
                        .foregroundColor(AppTheme.primaryColor)
                        .clipShape(Capsule())
                    }
                    .disabled(aiService.isGenerating)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Input

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("输入你的穿搭问题...", text: $inputText, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .focused($isInputFocused)

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiService.isGenerating
                        ? Color.gray
                        : AppTheme.primaryColor
                    )
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiService.isGenerating)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        isInputFocused = false
        Task { await aiService.sendMessage(text) }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .assistant {
                assistantAvatar
            }

            if message.role == .user { Spacer(minLength: 50) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.role == .user
                        ? AnyShapeStyle(AppTheme.accentGradient)
                        : AnyShapeStyle(Color(.systemGray6))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(timeString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if message.role == .assistant { Spacer(minLength: 50) }

            if message.role == .user {
                userAvatar
            }
        }
    }

    private var assistantAvatar: some View {
        ZStack {
            Circle()
                .fill(AppTheme.accentGradient)
                .frame(width: 32, height: 32)
            Image(systemName: "sparkles")
                .font(.caption)
                .foregroundColor(.white)
        }
    }

    private var userAvatar: some View {
        ZStack {
            Circle()
                .fill(Color(.systemGray4))
                .frame(width: 32, height: 32)
            Image(systemName: "person.fill")
                .font(.caption)
                .foregroundColor(.white)
        }
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: message.timestamp)
    }
}
