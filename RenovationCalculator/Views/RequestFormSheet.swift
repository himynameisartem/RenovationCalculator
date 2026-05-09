import SwiftUI

struct RequestFormSheet: View {
    let estimateLinesText: String?
    let onSubmit: (_ name: String, _ phone: String, _ email: String, _ comment: String, _ estimate: String?) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var comment = ""
    @State private var agreeToPolicy = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isSending = false
    @FocusState private var focusedField: Field?
    
    private let policyURL = URL(string: "https://example.com")!
    
    private enum Field: Hashable {
        case name, phone, email, comment
    }

    private var canSubmit: Bool {
        isPhoneValid && isEmailValid && agreeToPolicy
    }
    
    private var isPhoneValid: Bool {
        let digits = phone.filter(\.isNumber)
        return digits.count >= 10
    }
    
    private var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return trimmed.range(of: regex, options: .regularExpression) != nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Form {
                    Section("Контакты") {
                        TextField("Введите имя (необязательно)", text: $name)
                            .textInputAutocapitalization(.words)
                            .focused($focusedField, equals: .name)

                        TextField("+7 (___) ___-__-__", text: $phone)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .focused($focusedField, equals: .phone)
                        
                        if !phone.isEmpty && !isPhoneValid {
                            Text("Некорректный телефон")
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        ZStack(alignment: .leading) {
                            if email.isEmpty {
                                Text(verbatim: "name@example.com")
                                    .foregroundStyle(Color(uiColor: .placeholderText))
                                    .allowsHitTesting(false)
                            }
                            TextField("", text: $email)
                                .foregroundColor(.primary)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .email)
                        }
                        if !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isEmailValid {
                            Text("Некорректный email")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

                    Section("Комментарий") {
                        TextField("Введите комментарий (необязательно)", text: $comment, axis: .vertical)
                            .lineLimit(3...6)
                            .focused($focusedField, equals: .comment)
                    }

                    Section {
                        HStack(alignment: .top, spacing: 10) {
                            Button {
                                agreeToPolicy.toggle()
                            } label: {
                                Image(systemName: agreeToPolicy ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(agreeToPolicy ? Color.blue : Color.secondary)
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .buttonStyle(.plain)

                            Text(consentText)
                                .font(.footnote)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } footer: {
                        Text("* Обязательные поля")
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .contentShape(Rectangle())
                .onTapGesture {
                    focusedField = nil
                    hideKeyboard()
                }

                Button {
                    isSending = true
                    sendToYandex()
                } label: {
                    ZStack {
                        // Если отправка идет — показываем крутилку
                        if isSending {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Заказать расчет")
                        }
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(canSubmit && !isSending ? Color.blue : Color(UIColor.systemGray4))
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .disabled(!canSubmit || isSending)
                // Алерт остается тот же
                .alert(alertTitle, isPresented: $showAlert) {
                    Button("OK") {
                        if alertTitle == "Успешно" { dismiss() }
                    }
                } message: {
                    Text(alertMessage)
                }
            }
            .navigationTitle("Заявка на расчет")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Готово") {
                        focusedField = nil
                        hideKeyboard()
                    }
                }
            }
        }
    }

    // MARK: - Сетевая часть
    private func sendToYandex() {
        // Чистим строку от случайных пробелов по краям
        let urlString = "https://functions.yandexcloud.net/d4etr5cmivffs85lr4d3".trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let url = URL(string: urlString) else {
            self.isSending = false
            self.alertTitle = "Ошибка"
            self.alertMessage = "Некорректная ссылка сервера"
            self.showAlert = true
            return
        }
        
        let safeEstimate = estimateLinesText ?? "Пусто"
        
        let fullEstimate = """
        Имя: \(name)
        Комментарий: \(comment)
        Смета: \(safeEstimate)
        """
        
        // Используем [String: Any], но кладем только проверенные типы
        let body: [String: Any] = [
            "phone": phone,
            "email": email,
            "estimate": fullEstimate
        ]
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        let session = URLSession(configuration: config)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            self.isSending = false
            return
        }
        
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isSending = false
                
                if let error = error as NSError? {
                    self.alertTitle = "Сбой сети"
                    let vpnCodes = [NSURLErrorSecureConnectionFailed, NSURLErrorCannotConnectToHost, NSURLErrorTimedOut, NSURLErrorNetworkConnectionLost, -9807, -9802, -9838, -1200]
                    
                    if vpnCodes.contains(error.code) {
                        self.alertMessage = "Защищенное соединение заблокировано. Если включен VPN — отключите его (код: \(error.code))"
                    } else {
                        self.alertMessage = error.localizedDescription
                    }
                    self.showAlert = true
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        self.alertTitle = "Успешно"
                        self.alertMessage = "Заявка принята!"
                        self.onSubmit(name, phone, email, comment, safeEstimate)
                    } else {
                        self.alertTitle = "Ошибка сервера"
                        self.alertMessage = "Статус: \(httpResponse.statusCode)"
                    }
                    self.showAlert = true
                }
            }
        }.resume()
    }

    private var consentText: AttributedString {
        var text = AttributedString("Ознакомилен(а) с политикой конфиденциальности и согласен(а) на обработку персональных данных")
        if let range = text.range(of: "политикой конфиденциальности") {
            text[range].link = policyURL
            text[range].foregroundColor = .blue
            text[range].underlineStyle = .single
        }
        return text
    }
}
