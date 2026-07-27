import Foundation
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = [
        ChatMessage(
            role: .assistant,
            text: "Здравствуйте. Я помогу с вопросами по ремонту,примерной стоимости работ и услугам компании."
        )
    ]
    @Published var draft = ""
    @Published var isSending = false
    @Published var errorText: String?

    private let apiClient: ChatAPIClient
    private let maxMessageLength = 500

    init(apiClient: ChatAPIClient? = nil) {
        self.apiClient = apiClient ?? ChatAPIClient()
    }

    func send() {
        let message = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty, !isSending else { return }

        if message.count > maxMessageLength {
            errorText = "Сообщение слишком длинное. Сократите его до 500 символов."
            return
        }

        draft = ""
        errorText = nil
        messages.append(ChatMessage(role: .user, text: message))
        isSending = true

        Task {
            do {
                let answer = try await apiClient.send(message: message)
                messages.append(ChatMessage(role: .assistant, text: answer))
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
}
