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

                Button("Заказать расчет") {
                    sendToYandex()
                    onSubmit(name, phone, email, comment, estimateLinesText)
                    dismiss()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(canSubmit ? Color.blue : Color(UIColor.systemGray4))
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .disabled(!canSubmit)
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
        guard let url = URL(string: "https://functions.yandexcloud.net/d4etr5cmivffs85lr4d3") else { return }
        
        
        let fullEstimate = """
        Имя: \(name)
        Комментарий: \(comment)
        
        Смета:
        \(estimateLinesText ?? "Смета пуста")
        """
        
        let body: [String: Any] = [
            "phone": phone,
            "email": email,
            "estimate": fullEstimate
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Ошибка JSON: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request).resume()
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
