import SwiftUI

// MARK: - CompanyPlaceholder

struct CompanyPlaceholder: Identifiable {
    let id: UUID
    let name: String
    let logoName: String
    let websiteURL: URL
    let phoneURL: URL
    let phone: String

    init(name: String, logoName: String, websiteURL: URL, phoneURL: URL, phone: String) {
        self.id = UUID()
        self.name = name
        self.logoName = logoName
        self.websiteURL = websiteURL
        self.phoneURL = phoneURL
        self.phone = phone
    }
}

// MARK: - FinalEstimateView

struct FinalEstimateView: View {
    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel: FinalEstimateViewModel
    @State private var isInfoHintVisible = false
    @State private var isManualInfoHint = false
    @State private var didShowInitialInfoHint = false
    @State private var selectedCompanyID: UUID? = nil
    @State private var showContactsSheet = false

    let lines: [EstimateSummaryLine]
    let total: Double
    private let infoBubbleHorizontalInset: CGFloat = 16

    // Статический массив — UUID создаётся один раз, не пересоздаётся при рендере
    private static let allCompanies: [CompanyPlaceholder] = [
        CompanyPlaceholder(
            name: "ГК Поколение", logoName: "pokolenieLogo",
            websiteURL: URL(string: "https://gkpokolenie.ru")!,
            phoneURL: URL(string: "tel:+79581005418")!, phone: "+7 958 100-54-18"),
        CompanyPlaceholder(
            name: "Легион", logoName: "legionLogo",
            websiteURL: URL(string: "https://legionremont.ru")!,
            phoneURL: URL(string: "tel:+79158303600")!, phone: "+7 915 830-36-00"),
        CompanyPlaceholder(
            name: "СК Фемели", logoName: "femeliLogo",
            websiteURL: URL(string: "https://skfamily.moscow")!,
            phoneURL: URL(string: "tel:+79158303600")!, phone: "+7 915 830-36-00"),
        CompanyPlaceholder(
            name: "СК Фемели", logoName: "femeliLogo",
            websiteURL: URL(string: "https://skfamily.moscow")!,
            phoneURL: URL(string: "tel:+79158303600")!, phone: "+7 915 830-36-00"),
        CompanyPlaceholder(
            name: "СК Фемели", logoName: "femeliLogo",
            websiteURL: URL(string: "https://skfamily.moscow")!,
            phoneURL: URL(string: "tel:+79158303600")!, phone: "+7 915 830-36-00"),
    ]

    private var selectedCompany: CompanyPlaceholder? {
        Self.allCompanies.first { $0.id == selectedCompanyID }
    }

    init(
        lines: [EstimateSummaryLine],
        total: Double,
        store: SavedEstimatesStore,
        router: AppRouter,
        onReset: @escaping () -> Void,
        onSave: @escaping () -> String
    ) {
        self.lines = lines
        self.total = total
        _viewModel = StateObject(wrappedValue: FinalEstimateViewModel(
            store: store, router: router, onReset: onReset, onSave: onSave
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {

                topProgressBar
                companiesSection

                totalCard
                    .padding(.horizontal, 16)

                Text("Детализация сметы")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.top, 2)
            }
            .padding(.bottom, 6)

            // ── Только детализация скролится ─────────────────────────
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    if lines.isEmpty {
                        Text("Смета пустая")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                    } else {
                        ForEach(lines) { line in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(line.title)
                                        .font(.system(size: 14))
                                    Text("\(line.quantity, specifier: "%.1f") \(line.unit) × \(line.unitPrice, specifier: "%.0f") ₽")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("\(Int(line.subtotal).formatted()) ₽")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: Color.black.opacity(0.05), radius: 6, y: 2)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }

            // ── Баннер всегда внизу ───────────────────────────────────
            ctaBanner
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 8)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .overlay(alignment: .topTrailing) {
            if isInfoHintVisible {
                infoHintBubble
                    .padding(.top, 12)
                    .padding(.trailing, 16)
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isInfoHintVisible {
                            isInfoHintVisible = false
                            isManualInfoHint = false
                        } else {
                            isManualInfoHint = true
                            isInfoHintVisible = true
                        }
                    }
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .task {
            guard !didShowInitialInfoHint else { return }
            didShowInitialInfoHint = true
            withAnimation(.easeInOut(duration: 0.25)) {
                isManualInfoHint = false
                isInfoHintVisible = true
            }
            try? await Task.sleep(for: .seconds(2))
            guard !isManualInfoHint else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                isInfoHintVisible = false
            }
        }
        .alert("Уверены?", isPresented: $viewModel.showResetAlert) {
            Button("Да, сбросить", role: .destructive) { viewModel.confirmResetAndStartNewCalculation() }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Если смета не сохранена, все расчеты будут удалены.")
        }
        .alert("Сохранение", isPresented: $viewModel.showSaveAlert) {
            Button("Ок", role: .cancel) {}
        } message: {
            Text(viewModel.saveMessage)
        }
        .sheet(isPresented: $showContactsSheet) {
            if let company = selectedCompany {
                CompanyContactsSheet(company: company, openURL: openURL)
            }
        }
    }

    // MARK: - Steps Bar

    private var topProgressBar: some View {
        HStack(spacing: 10) {
            progressItem(title: "Помещения", number: 1, state: .done)
            progressItem(title: "Работы", number: 2, state: .done)
            progressItem(title: "Итог", number: 3, state: .active)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }

    private enum ProgressState {
        case done
        case active
        case inactive
    }

    private func progressItem(title: String, number: Int, state: ProgressState) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(circleColor(state))
                .frame(width: 28, height: 28)
                .overlay {
                    if state == .done {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    } else {
                        Text("\(number)")
                            .font(.caption.bold())
                            .foregroundColor(
                                state == .inactive ? .black : .white
                        )
                    }
                }
            
            Text(title)
                .font(.caption.bold())
                .foregroundColor(textColor(state))
        }
        .frame(maxWidth: .infinity)
    }

    private func circleColor(_ state: ProgressState) -> Color {
        switch state {
        case .done: return .blue
        case .active: return .blue
        case .inactive: return Color(.systemGray4)
        }
    }

    private func textColor(_ state: ProgressState) -> Color {
        switch state {
        case .done: return .blue
        case .active: return .blue
        case .inactive: return .gray
        }
    }

    // MARK: - Companies Section (без скролла, равномерно на ширину экрана)

    private var companiesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Список компаний")
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 16)

            Text("Ниже приведены примеры компаний для ориентира. Вы можете выбрать любую другую компанию или подрядчика по своему усмотрению.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)

            // Равномерное распределение по ширине, без скролла
            HStack(spacing: 0) {
                ForEach(Self.allCompanies) { company in
                    CompanyCardView(
                        company: company,
                        isSelected: selectedCompanyID == company.id
                    ) {
                        withAnimation(.spring(response: 0.25)) {
                            if selectedCompanyID == company.id {
                                selectedCompanyID = nil
                            } else {
                                selectedCompanyID = company.id
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)
        }
    }

    // MARK: - Total Card

    private var totalCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: "doc.text")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Итого по смете:")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text("\(Int(total).formatted()) ₽")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.blue)
            }

            Spacer()

            Button { viewModel.saveEstimate() } label: {
                HStack(spacing: 5) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 12, weight: .medium))
                    Text("Сохранить смету")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 8, y: 3)
    }

    // MARK: - CTA Banner

    private var ctaBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "headphones")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Готовы начать ремонт?")
                    .font(.system(size: 13, weight: .semibold))
                Text("Выберите компанию и мы свяжемся с вами. Так же вы можете самостоятельно связаться с нами по ссылке в контактах.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)

            VStack(spacing: 6) {
                Button {
                    // TODO: заказать звонок
                } label: {
                    Text("Заказать звонок")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.green))
                }
                .buttonStyle(.plain)

                Button {
                    guard selectedCompany != nil else { return }
                    showContactsSheet = true
                } label: {
                    Text("Контакты")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(selectedCompany != nil ? Color.blue : Color(UIColor.systemGray4))
                        )
                }
                .buttonStyle(.plain)
                .allowsHitTesting(selectedCompany != nil)
            }
            .frame(width: 130)
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.07), radius: 8, y: 3)
    }

    // MARK: - Info Hint

    private var infoHintBubble: some View {
        VStack(alignment: .trailing, spacing: 0) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .frame(width: 14, height: 14)
                .rotationEffect(.degrees(45))
                .padding(.trailing, 22)
                .padding(.bottom, -7)

            Text("Указанные компании приведены в качестве примеров и не ограничивают ваш выбор подрядчика. Итоговая стоимость уточняется напрямую у выбранной компании.")
                .font(.footnote)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .padding(10)
                .frame(
                    maxWidth: min(UIScreen.main.bounds.width - (infoBubbleHorizontalInset * 2), 290),
                    alignment: .leading
                )
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                )
                .shadow(color: Color.black.opacity(0.08), radius: 10, y: 4)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - CompanyCardView

private struct CompanyCardView: View {
    let company: CompanyPlaceholder
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 5) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white)
                        .frame(width: 56, height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    isSelected ? Color.blue : Color(UIColor.systemGray5),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                        .shadow(
                            color: isSelected ? Color.blue.opacity(0.25) : Color.black.opacity(0.04),
                            radius: 5, y: 2
                        )

                    Image(company.logoName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38, height: 38)
                        .frame(width: 56, height: 56)

                    if isSelected {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 16, height: 16)
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: 5, y: -5)
                        .transition(.scale.combined(with: .opacity))
                    }
                }

                Text(company.name)
                    .font(.system(size: 9))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: 60)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - CompanyContactsSheet

private struct CompanyContactsSheet: View {
    let company: CompanyPlaceholder
    let openURL: OpenURLAction
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(UIColor.systemGray4))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 24)

            Image(company.logoName)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(UIColor.systemGray5), lineWidth: 1)
                )
                .padding(.bottom, 12)

            Text(company.name)
                .font(.system(size: 20, weight: .bold))
                .padding(.bottom, 24)

            VStack(spacing: 10) {
                Button { openURL(company.websiteURL) } label: {
                    HStack {
                        Image(systemName: "globe").foregroundColor(.blue).frame(width: 28)
                        Text(company.websiteURL.host ?? company.websiteURL.absoluteString).foregroundColor(.blue)
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(Color(UIColor.systemGray3))
                    }
                    .padding(14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button { openURL(company.phoneURL) } label: {
                    HStack {
                        Image(systemName: "phone.fill").foregroundColor(.green).frame(width: 28)
                        Text(company.phone).foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(Color(UIColor.systemGray3))
                    }
                    .padding(14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)

            Spacer()

            Button { dismiss() } label: {
                Text("Закрыть")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.blue))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}
