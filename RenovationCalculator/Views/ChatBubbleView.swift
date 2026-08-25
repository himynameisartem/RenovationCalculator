import SwiftUI

struct ChatBubbleView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var isOpen: Bool
    let cardsBottom: CGFloat
    let bottomBoundary: CGFloat
    @State private var keyboardHeight: CGFloat = 0
    @State private var isChatHintVisible = true
    @State private var isChatHintExpanded = false
    @State private var chatHintTask: Task<Void, Never>?
    @FocusState private var isInputFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomTrailing) {
                if isOpen {
                    chatCard(in: geometry)
                        .padding(.horizontal, 16)
                        .padding(.bottom, cardBottomPadding)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if keyboardHeight == 0 && !isOpen {
                    let controlHeight: CGFloat = isChatHintVisible && isChatHintExpanded ? 68 : 58

                    Group {
                        if isChatHintVisible {
                            chatHintButton(width: geometry.size.width - 32)
                                .padding(.horizontal, 16)
                        } else {
                            chatButton
                                .padding(.trailing, 16)
                        }
                    }
                    .padding(.bottom, chatBottomPadding(in: geometry, controlHeight: controlHeight))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            updateKeyboardHeight(from: notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.22)) {
                keyboardHeight = 0
            }
        }
        .onAppear {
            scheduleChatHint()
        }
        .onDisappear {
            chatHintTask?.cancel()
        }
    }

    private var cardBottomPadding: CGFloat {
        keyboardHeight > 0 ? keyboardHeight + 12 : 104
    }

    private var chatButton: some View {
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                isOpen.toggle()
            }
        } label: {
            Image(systemName: isOpen ? "xmark" : "message.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 58, height: 58)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 63/255, green: 123/255, blue: 227/255),
                            Color(red: 91/255, green: 166/255, blue: 242/255)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.22), radius: 18, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private func chatHintButton(width: CGFloat) -> some View {
        let height: CGFloat = isChatHintExpanded ? 68 : 58

        return HStack(spacing: 0) {
            Button(action: dismissChatHint) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: isChatHintExpanded ? 44 : 0, height: height)
                    .opacity(isChatHintExpanded ? 1 : 0)
            }
            .buttonStyle(.plain)
            .allowsHitTesting(isChatHintExpanded)
            .accessibilityLabel("Закрыть подсказку")

            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    isChatHintVisible = false
                    isOpen = true
                }
            } label: {
                HStack(spacing: 10) {
                    Text("Есть вопрос по ремонту?\nСпросите ИИ-помощника")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .opacity(isChatHintExpanded ? 1 : 0)

                    Spacer(minLength: 0)

                    Image(systemName: "message.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 58, height: height)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(width: isChatHintExpanded ? width : 58, height: height, alignment: .trailing)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 63/255, green: 123/255, blue: 227/255),
                    Color(red: 91/255, green: 166/255, blue: 242/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.22), radius: 18, x: 0, y: 8)
    }

    private func dismissChatHint() {
        chatHintTask?.cancel()

        withAnimation(.easeOut(duration: 0.25)) {
            isChatHintExpanded = false
        }

        Task {
            try? await Task.sleep(for: .milliseconds(260))
            guard !Task.isCancelled else { return }
            isChatHintVisible = false
        }
    }

    private func scheduleChatHint() {
        chatHintTask?.cancel()
        isChatHintVisible = true
        isChatHintExpanded = false

        chatHintTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { return }

                withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                    isChatHintExpanded = true
                }

                try? await Task.sleep(for: .seconds(7))
                guard !Task.isCancelled else { return }

                withAnimation(.easeOut(duration: 0.25)) {
                    isChatHintExpanded = false
                }

                try? await Task.sleep(for: .seconds(5))
            }
        }
    }

    private func chatBottomPadding(in geometry: GeometryProxy, controlHeight: CGFloat) -> CGFloat {
        let screenBottom = geometry.frame(in: .global).maxY
        let availableGap = bottomBoundary - cardsBottom - controlHeight

        guard cardsBottom > 0, availableGap >= 0 else {
            return 16
        }

        // All values are in the Home screen's coordinate space.
        let controlBottom = cardsBottom + (availableGap / 2) + controlHeight
        return screenBottom - controlBottom
    }

    private func chatCard(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            header
            Divider()
            messagesList
            inputBar
        }
        .frame(
            width: min(geometry.size.width - 32, 360),
            height: chatCardHeight(in: geometry)
        )
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Color.black.opacity(0.2), radius: 28, x: 0, y: 14)
    }

    private func chatCardHeight(in geometry: GeometryProxy) -> CGFloat {
        let reservedBottom = keyboardHeight > 0 ? keyboardHeight + 28 : 220
        let availableHeight = geometry.size.height - reservedBottom - geometry.safeAreaInsets.top - 16
        return min(max(availableHeight, 320), 500)
    }

    private func updateKeyboardHeight(from notification: Notification) {
        guard
            let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }

        let screenHeight = UIScreen.main.bounds.height
        let height = max(0, screenHeight - frame.minY)

        withAnimation(.easeOut(duration: duration)) {
            keyboardHeight = height
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(red: 63/255, green: 123/255, blue: 227/255).opacity(0.12))
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 63/255, green: 123/255, blue: 227/255))
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text("ИИ помощник")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)
                Text("Отвечает по вопросам ремонта")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                closeChat()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .contentShape(Rectangle())
        .onTapGesture {
            dismissKeyboard()
        }
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(viewModel.messages) { message in
                        ChatMessageRow(message: message)
                            .id(message.id)
                    }

                    if viewModel.isSending {
                        ChatTypingRow()
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                dismissKeyboard()
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(proxy)
            }
            .onChange(of: viewModel.isSending) { _, _ in
                scrollToBottom(proxy)
            }
        }
    }

    private var inputBar: some View {
        VStack(spacing: 8) {
            if let errorText = viewModel.errorText {
                Text(errorText)
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text("Ответы генерирует ИИ, он может ошибаться. Проверяйте важную информацию у менеджера.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            HStack(spacing: 10) {
                TextField("Ваш вопрос", text: $viewModel.draft, axis: .vertical)
                    .lineLimit(1...3)
                    .font(.system(size: 15))
                    .focused($isInputFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )

                Button {
                    viewModel.send()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(
                            Circle()
                                .fill(viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                        )
                }
                .disabled(viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
            }
        }
        .padding(14)
        .background(Color(UIColor.systemBackground))
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard let lastID = viewModel.messages.last?.id else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(lastID, anchor: .bottom)
        }
    }

    private func dismissKeyboard() {
        withAnimation(.easeOut(duration: 0.22)) {
            isInputFocused = false
        }
    }

    private func closeChat() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            isInputFocused = false
            isOpen = false
        }
    }
}

private struct ChatMessageRow: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .assistant {
                bubble
                Spacer(minLength: 32)
            } else {
                Spacer(minLength: 32)
                bubble
            }
        }
    }

    private var bubble: some View {
        Text(message.text)
            .font(.system(size: 14))
            .foregroundColor(message.role == .assistant ? .primary : .white)
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(message.role == .assistant ? Color(UIColor.secondarySystemBackground) : Color.blue)
            )
    }
}

private struct ChatTypingRow: View {
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.72)
                Text("Печатает...")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            Spacer(minLength: 32)
        }
    }
}
