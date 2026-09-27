import PhotosUI
import SwiftUI

struct ChatBubbleView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var viewModel: ChatViewModel
    @Binding var isOpen: Bool
    let cardsBottom: CGFloat
    let bottomBoundary: CGFloat
    @State private var keyboardFrame: CGRect = .zero
    @State private var isChatHintVisible = true
    @State private var isChatHintExpanded = false
    @State private var chatHintTask: Task<Void, Never>?
    @State private var photoHintTask: Task<Void, Never>?
    @State private var isPhotoHintVisible = false
    @State private var isPhotoSourceOpen = false
    @State private var isGalleryOpen = false
    @State private var isCameraOpen = false
    @State private var isCameraBatchOpen = false
    @State private var isCameraUnavailable = false
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var capturedImages: [Data] = []
    @FocusState private var isInputFocused: Bool

    var body: some View {
        chatOverlay
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
                updateKeyboardHeight(from: notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeOut(duration: 0.22)) {
                    keyboardFrame = .zero
                }
            }
            .onAppear {
                scheduleChatHint()
            }
            .onDisappear {
                chatHintTask?.cancel()
                photoHintTask?.cancel()
            }
            .onChange(of: isOpen) { _, isOpen in
                if isOpen {
                    viewModel.refreshSessionState()
                    showPhotoHintIfNeeded()
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    viewModel.refreshSessionState()
                }
            }
            .confirmationDialog("Добавить фото", isPresented: $isPhotoSourceOpen) {
                Button("Камера") {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        isCameraOpen = true
                    } else {
                        isCameraUnavailable = true
                    }
                }
                Button("Галерея") { isGalleryOpen = true }
                Button("Отмена", role: .cancel) {}
            }
            .photosPicker(
                isPresented: $isGalleryOpen,
                selection: $pickerItems,
                maxSelectionCount: 3,
                matching: .images
            )
            .onChange(of: pickerItems) { _, items in
                loadGalleryImages(items)
            }
            .fullScreenCover(isPresented: $isCameraOpen) {
                CameraImagePicker { image in
                    guard let data = image.jpegData(compressionQuality: 0.9) else { return }
                    capturedImages.append(data)
                    Task {
                        try? await Task.sleep(for: .milliseconds(350))
                        isCameraBatchOpen = true
                    }
                }
                .ignoresSafeArea()
            }
            .confirmationDialog(
                "Сделано фото: \(capturedImages.count) из 3",
                isPresented: $isCameraBatchOpen
            ) {
                if capturedImages.count < 3 {
                    Button("Сделать ещё фото") { isCameraOpen = true }
                }
                Button("Отправить \(capturedImages.count) фото") {
                    let images = capturedImages
                    capturedImages = []
                    viewModel.beginPhotoEstimate(imageData: images)
                }
                Button("Отменить", role: .destructive) {
                    capturedImages = []
                }
            }
            .alert("Камера недоступна", isPresented: $isCameraUnavailable) {
                Button("OK", role: .cancel) {}
            }
    }

    @ViewBuilder
    private var chatOverlay: some View {
        chatOverlayContent
    }

    private var chatOverlayContent: some View {
        GeometryReader { geometry in
            let keyboardOverlap = keyboardOverlap(in: geometry)
            let isKeyboardVisible = keyboardFrame != .zero

            ZStack(alignment: .bottomTrailing) {
                if isOpen {
                    chatCard(in: geometry)
                        .padding(.horizontal, 16)
                        .padding(.bottom, cardBottomPadding(
                            keyboardOverlap: keyboardOverlap,
                            isKeyboardVisible: isKeyboardVisible
                        ))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if !isKeyboardVisible && !isOpen {
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
    }

    private func cardBottomPadding(
        keyboardOverlap: CGFloat,
        isKeyboardVisible: Bool
    ) -> CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            let screenKeyboardHeight = keyboardFrame == .zero
                ? 0
                : max(0, UIScreen.main.bounds.height - keyboardFrame.minY)
            return screenKeyboardHeight > 0 ? screenKeyboardHeight + 12 : 104
        }

        return isKeyboardVisible ? 12 : 104
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
        if UIDevice.current.userInterfaceIdiom == .pad {
            let screenKeyboardHeight = keyboardFrame == .zero
                ? 0
                : max(0, UIScreen.main.bounds.height - keyboardFrame.minY)
            let reservedBottom = screenKeyboardHeight > 0 ? screenKeyboardHeight + 28 : 220
            let availableHeight = geometry.size.height - reservedBottom - geometry.safeAreaInsets.top - 16
            return min(max(availableHeight, 320), 500)
        }

        guard keyboardFrame != .zero else {
            let availableHeight = geometry.size.height - 220 - geometry.safeAreaInsets.top - 16
            return min(max(availableHeight, 320), 500)
        }

        // GeometryReader is already reduced to the area above the keyboard on iPhone.
        let availableHeight = geometry.size.height - geometry.safeAreaInsets.top - 24
        return max(280, availableHeight)
    }

    private func updateKeyboardHeight(from notification: Notification) {
        guard
            let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }

        // UIKit animates the safe-area change. Animating this value separately caused
        // an additional size transition for the chat card.
        keyboardFrame = frame
    }

    private func keyboardOverlap(in geometry: GeometryProxy) -> CGFloat {
        guard keyboardFrame != .zero else { return 0 }
        return max(0, geometry.frame(in: .global).maxY - keyboardFrame.minY)
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

            if viewModel.isSessionLimitReached {
                Text("Достигнут лимит сообщений. Диалог очистится автоматически через некоторое время.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text("Ответы генерирует ИИ, он может ошибаться. Проверяйте важную информацию у менеджера.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            HStack(spacing: 10) {
                Button {
                    dismissKeyboard()
                    isPhotoSourceOpen = true
                } label: {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(width: 38, height: 38)
                        .background(
                            Circle().fill(Color.blue.opacity(0.10))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Рассчитать по фотографиям")

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
                    .disabled(viewModel.isSessionLimitReached)

                Button {
                    viewModel.send()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(
                            Circle()
                                .fill(
                                    viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSessionLimitReached
                                        ? Color.gray.opacity(0.5)
                                        : Color.blue
                                )
                        )
                }
                .disabled(
                    viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || viewModel.isSending
                        || viewModel.isSessionLimitReached
                )
            }
            .overlay(alignment: .bottomLeading) {
                if isPhotoHintVisible {
                    photoHintBubble
                        .offset(x: 0, y: -52)
                        .transition(.scale(scale: 0.9, anchor: .bottomLeading).combined(with: .opacity))
                }
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

    private func loadGalleryImages(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        Task {
            var images: [Data] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    images.append(data)
                }
            }
            pickerItems = []
            if !images.isEmpty {
                viewModel.beginPhotoEstimate(imageData: images)
            }
        }
    }

    private var photoHintBubble: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("Для более точного расчёта можно загрузить до трёх фотографий помещения")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                hidePhotoHint()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: 255)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.blue)
        )
        .shadow(color: .black.opacity(0.18), radius: 10, y: 5)
        .onTapGesture {
            hidePhotoHint()
        }
    }

    private func showPhotoHintIfNeeded() {
        guard viewModel.consumePhotoHint() else { return }
        photoHintTask?.cancel()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            isPhotoHintVisible = true
        }
        photoHintTask = Task {
            try? await Task.sleep(for: .seconds(7))
            guard !Task.isCancelled else { return }
            hidePhotoHint()
        }
    }

    private func hidePhotoHint() {
        photoHintTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) {
            isPhotoHintVisible = false
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
        VStack(alignment: .leading, spacing: 8) {
            if !message.imageData.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(message.imageData.enumerated()), id: \.offset) { _, data in
                            if let image = UIImage(data: data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 96, height: 96)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                    }
                }
            }

            if !message.text.isEmpty {
                Text(message.text)
                    .font(.system(size: 14))
                    .foregroundColor(message.role == .assistant ? .primary : .white)
            }
        }
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(message.role == .assistant ? Color(UIColor.secondarySystemBackground) : Color.blue)
            )
    }
}

private struct CameraImagePicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraImagePicker

        init(parent: CameraImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImage(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
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
