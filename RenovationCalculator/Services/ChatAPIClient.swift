import Foundation

final class ChatAPIClient {
    private let endpoint = URL(string: "https://cucosinepsiey.beget.app/chat")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func send(messages: [ChatMessage]) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body = ChatRequest(
            messages: messages.map {
                ChatRequestMessage(
                    role: $0.role == .user ? "user" : "assistant",
                    content: $0.text
                )
            }
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatAPIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw ChatAPIError.server(statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(ChatResponse.self, from: data).answer
    }
}

private struct ChatRequest: Encodable {
    let messages: [ChatRequestMessage]
}

private struct ChatRequestMessage: Encodable {
    let role: String
    let content: String
}

private struct ChatResponse: Decodable {
    let answer: String
}

enum ChatAPIError: LocalizedError {
    case invalidResponse
    case server(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Не удалось получить ответ сервера."
        case .server:
            return "Сервер временно недоступен. Попробуйте позже."
        }
    }
}
