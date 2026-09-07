import Foundation
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = [ChatViewModel.welcomeMessage()]
    @Published var draft = ""
    @Published private(set) var isSending = false
    @Published var errorText: String?
    @Published private(set) var remainingQuestions = 10

    private let apiClient: ChatAPIClient
    private let maxMessageLength = 500
    private let maxQuestions = 10
    private let maxHistoryMessages = 10
    private let sessionTimeout: TimeInterval = 5 * 60

    private var conversationMessages: [ChatMessage] = []
    private var lastQuestionAt: Date?
    private var expirationTask: Task<Void, Never>?

    var isSessionLimitReached: Bool {
        remainingQuestions == 0
    }

    init(apiClient: ChatAPIClient? = nil) {
        self.apiClient = apiClient ?? ChatAPIClient()
    }

    func send() {
        refreshSessionState()

        let message = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty, !isSending else { return }

        guard !isSessionLimitReached else {
            errorText = "Лимит 10 вопросов исчерпан. Диалог очистится через 5 минут после последнего вопроса."
            return
        }

        if message.count > maxMessageLength {
            errorText = "Сообщение слишком длинное. Сократите его до 500 символов."
            return
        }

        draft = ""
        errorText = nil
        let userMessage = ChatMessage(role: .user, text: message)
        messages.append(userMessage)
        conversationMessages.append(userMessage)
        remainingQuestions -= 1
        lastQuestionAt = Date()
        scheduleExpiration()

        let requestMessages = Array(conversationMessages.dropLast().suffix(maxHistoryMessages)) + [userMessage]
        isSending = true

        Task {
            do {
                let answer = try await apiClient.send(messages: requestMessages)
                let assistantMessage = ChatMessage(role: .assistant, text: answer)
                messages.append(assistantMessage)
                conversationMessages.append(assistantMessage)
            } catch {
                errorText = error.localizedDescription
                messages.append(
                    ChatMessage(
                        role: .assistant,
                        text: "Не удалось получить ответ. Проверьте подключение и попробуйте еще раз."
                    )
                )
            }

            isSending = false
        }
    }

    func refreshSessionState(now: Date = Date()) {
        guard let lastQuestionAt else { return }
        guard now.timeIntervalSince(lastQuestionAt) >= sessionTimeout else { return }
        resetSession()
    }

    private func scheduleExpiration() {
        expirationTask?.cancel()
        expirationTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(5 * 60))
            guard !Task.isCancelled else { return }
            self?.refreshSessionState()
        }
    }

    private func resetSession() {
        expirationTask?.cancel()
        expirationTask = nil
        conversationMessages.removeAll()
        messages = [Self.welcomeMessage()]
        draft = ""
        errorText = nil
        remainingQuestions = maxQuestions
        lastQuestionAt = nil
    }

    private static func welcomeMessage() -> ChatMessage {
        ChatMessage(
            role: .assistant,
            text: "Здравствуйте. Я помогу с вопросами по ремонту, примерной стоимости работ и услугам компании."
        )
    }
}
