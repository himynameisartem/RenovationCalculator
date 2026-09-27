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
    private let photoEstimateClient: PhotoEstimateAPIClient
    private let maxMessageLength = 500
    private let maxQuestions = 10
    private let maxHistoryMessages = 10
    private let sessionTimeout: TimeInterval = 5 * 60

    private var conversationMessages: [ChatMessage] = []
    private var lastQuestionAt: Date?
    private var expirationTask: Task<Void, Never>?
    private var photoStep: PhotoStep = .idle
    private var pendingSurfaces: RoomSurfaceAnalysis?
    private var pendingArea: Double?
    private var pendingImageData: [Data] = []
    private var didShowPhotoHint = false

    private enum PhotoStep: Equatable {
        case idle
        case analyzing
        case awaitingArea
        case awaitingHeight
        case estimating
    }

    var isSessionLimitReached: Bool {
        remainingQuestions == 0
    }

    init(
        apiClient: ChatAPIClient? = nil,
        photoEstimateClient: PhotoEstimateAPIClient? = nil
    ) {
        self.apiClient = apiClient ?? ChatAPIClient()
        self.photoEstimateClient = photoEstimateClient ?? (try! PhotoEstimateAPIClient(
            baseURL: "http://192.168.1.70:8000"
        ))
    }

    func send() {
        refreshSessionState()

        let message = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty, !isSending else { return }

        if photoStep == .awaitingArea || photoStep == .awaitingHeight {
            sendPhotoParameter(message)
            return
        }

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

    func consumePhotoHint() -> Bool {
        guard !didShowPhotoHint else { return false }
        didShowPhotoHint = true
        return true
    }

    func beginPhotoEstimate(imageData: [Data]) {
        guard !imageData.isEmpty, !isSending else { return }

        let isAddingDetails = photoStep == .awaitingArea && !pendingImageData.isEmpty
        let combinedImages = Array((isAddingDetails ? pendingImageData + imageData : imageData).prefix(3))
        draft = ""
        errorText = nil
        if !isAddingDetails {
            pendingSurfaces = nil
            pendingArea = nil
        }
        pendingImageData = combinedImages
        photoStep = .analyzing
        messages.append(ChatMessage(role: .user, text: "", imageData: imageData))
        isSending = true

        Task {
            do {
                let surfaces = try await MobileCVService.shared.analyze(imageData: combinedImages)
                pendingSurfaces = surfaces
                let missingSurfaces = missingSurfaceNames(in: surfaces)
                photoStep = .awaitingArea
                if missingSurfaces.isEmpty {
                    messages.append(ChatMessage(
                        role: .assistant,
                        text: "Введите площадь помещения в м²."
                    ))
                } else {
                    messages.append(ChatMessage(
                        role: .assistant,
                        text: "Для более точного результата добавьте фото, где лучше видны \(joinedSurfaceNames(missingSurfaces)). Либо сразу введите площадь помещения — расчёт будет выполнен по имеющимся фотографиям."
                    ))
                }
            } catch MobileCVError.notRoom {
                pendingSurfaces = nil
                pendingArea = nil
                pendingImageData = []
                photoStep = .idle
                messages.append(ChatMessage(
                    role: .assistant,
                    text: "На снимке не удалось увидеть помещение. Добавьте фото комнаты общим планом, чтобы были видны стены и пол или потолок."
                ))
            } catch MobileCVError.noSurfaces {
                pendingSurfaces = nil
                pendingArea = nil
                pendingImageData = []
                photoStep = .idle
                messages.append(ChatMessage(
                    role: .assistant,
                    text: "По этому снимку не удалось оценить состояние комнаты. Добавьте другое фото общим планом."
                ))
            } catch {
                photoStep = .idle
                errorText = error.localizedDescription
                messages.append(ChatMessage(
                    role: .assistant,
                    text: "Не удалось распознать поверхности на фотографиях. Попробуйте выбрать другие снимки."
                ))
            }
            isSending = false
        }
    }

    private func sendPhotoParameter(_ message: String) {
        guard let value = firstNumber(in: message), value > 0 else {
            draft = ""
            messages.append(ChatMessage(role: .user, text: message))
            messages.append(ChatMessage(
                role: .assistant,
                text: photoStep == .awaitingArea
                    ? "Укажите площадь числом, например: 18,5."
                    : "Укажите высоту числом, например: 2,7."
            ))
            return
        }

        draft = ""
        errorText = nil
        messages.append(ChatMessage(role: .user, text: message))

        if photoStep == .awaitingArea {
            pendingArea = value
            photoStep = .awaitingHeight
            messages.append(ChatMessage(
                role: .assistant,
                text: "Введите высоту потолка в метрах."
            ))
            return
        }

        guard photoStep == .awaitingHeight,
              let surfaces = pendingSurfaces,
              let area = pendingArea else {
            photoStep = .idle
            return
        }

        photoStep = .estimating
        isSending = true
        Task {
            do {
                let response = try await photoEstimateClient.estimate(
                    surfaces: surfaces,
                    roomType: "other",
                    roomName: "Помещение",
                    area: area,
                    height: value
                )
                let assistantMessage = ChatMessage(role: .assistant, text: response.answer)
                messages.append(assistantMessage)
                conversationMessages.append(assistantMessage)
            } catch {
                errorText = error.localizedDescription
                messages.append(ChatMessage(
                    role: .assistant,
                    text: "Не удалось получить расчёт. Проверьте подключение и попробуйте ещё раз."
                ))
            }
            pendingSurfaces = nil
            pendingArea = nil
            pendingImageData = []
            photoStep = .idle
            isSending = false
        }
    }

    private func firstNumber(in text: String) -> Double? {
        let normalized = text.replacingOccurrences(of: ",", with: ".")
        guard let range = normalized.range(of: #"\d+(?:\.\d+)?"#, options: .regularExpression) else {
            return nil
        }
        return Double(normalized[range])
    }

    private func missingSurfaceNames(in surfaces: RoomSurfaceAnalysis) -> [String] {
        let visible = Set(surfaces.visibleSurfaces)
        var result: [String] = []
        if !visible.contains("walls") { result.append("стены") }
        if !visible.contains("floor") { result.append("пол") }
        if !visible.contains("ceiling") { result.append("потолок") }
        return result
    }

    private func joinedSurfaceNames(_ names: [String]) -> String {
        guard names.count > 1 else { return names.first ?? "все поверхности" }
        return names.dropLast().joined(separator: ", ") + " и " + (names.last ?? "")
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
        pendingSurfaces = nil
        pendingArea = nil
        pendingImageData = []
        photoStep = .idle
        isSending = false
    }

    private static func welcomeMessage() -> ChatMessage {
        ChatMessage(
            role: .assistant,
            text: "Здравствуйте. Я помогу с вопросами по ремонту, примерной стоимости работ и услугам компании."
        )
    }
}
