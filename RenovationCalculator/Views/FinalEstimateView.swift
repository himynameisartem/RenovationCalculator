import SwiftUI

struct FinalEstimateView: View {
    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel: FinalEstimateViewModel
    @State private var isInfoHintVisible = false
    @State private var isManualInfoHint = false
    @State private var didShowInitialInfoHint = false
    let lines: [EstimateSummaryLine]
    let total: Double

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
        _viewModel = StateObject(
            wrappedValue: FinalEstimateViewModel(
                store: store,
                router: router,
                onReset: onReset,
                onSave: onSave
            )
        )
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Смета")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                Text("Список компаний")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)

                VStack(spacing: 8) {
                    ForEach(placeholderCompanies) { company in
                        companyRow(company)
                    }
                }
                .padding(.horizontal, 16)

                Text("Смета")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                estimateContent
                    .padding(.horizontal, 16)
            }

            Spacer(minLength: 0)

            Text("Итого: \(total, specifier: "%.0f") ₽")
                .font(.title3)
                .padding(.top, 4)
        }
        .padding(.bottom, 130)
        .appScreenBackground()
        .contentShape(Rectangle())
        .onTapGesture {
            guard isInfoHintVisible else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                isInfoHintVisible = false
                isManualInfoHint = false
            }
        }
        .overlay {
            if isInfoHintVisible {
                Color.black.opacity(0.08)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .overlay(alignment: .topTrailing) {
            if isInfoHintVisible {
                infoHintBubble
                    .padding(.top, 12)
                    .padding(.trailing, 16)
                    .transition(.opacity)
            }
        }
        .overlay(alignment: .bottom) {
            floatingBottomActions
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
                    Image(systemName: "info")
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
            Button("Да, сбросить", role: .destructive) {
                viewModel.confirmResetAndStartNewCalculation()
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Если смета не сохранена, все расчеты будут удалены.")
        }
        .alert("Сохранение", isPresented: $viewModel.showSaveAlert) {
            Button("Ок", role: .cancel) { }
        } message: {
            Text(viewModel.saveMessage)
        }
    }

    private var infoHintBubble: some View {
        VStack(alignment: .trailing, spacing: 0) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .frame(width: 14, height: 14)
                .rotationEffect(.degrees(45))
                .overlay {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        .rotationEffect(.degrees(45))
                }
                .offset(x: -26, y: 7)
                .zIndex(1)

            VStack(alignment: .leading, spacing: 10) {
                Text("Цена может измениться. Для уточнения обратитесь в выбранную компанию.")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }
            .padding(12)
            .fixedSize(horizontal: false, vertical: true)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.08), radius: 12, y: 6)
        }
    }

    private var placeholderCompanies: [CompanyPlaceholder] {
        [
            CompanyPlaceholder(
                name: "Компания 1",
                logoSystemName: "building.2.crop.circle",
                websiteURL: URL(string: "https://example.com")!,
                phoneURL: URL(string: "tel:+70000000001")!
            ),
            CompanyPlaceholder(
                name: "Компания 2",
                logoSystemName: "hammer.circle",
                websiteURL: URL(string: "https://example.com")!,
                phoneURL: URL(string: "tel:+70000000002")!
            ),
            CompanyPlaceholder(
                name: "Компания 3",
                logoSystemName: "wrench.and.screwdriver.fill",
                websiteURL: URL(string: "https://example.com")!,
                phoneURL: URL(string: "tel:+70000000003")!
            )
        ]
    }

    private struct CompanyPlaceholder: Identifiable {
        let id = UUID()
        let name: String
        let logoSystemName: String
        let websiteURL: URL
        let phoneURL: URL
    }

    @ViewBuilder
    private var estimateContent: some View {
        if lines.isEmpty {
            Text("Смета пустая")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                )
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(lines) { line in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(line.title)
                                Text("\(line.quantity, specifier: "%.1f") \(line.unit) × \(line.unitPrice, specifier: "%.0f") ₽")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(line.subtotal, specifier: "%.0f") ₽")
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        )
                    }
                }
            }
            .frame(maxHeight: 260)
            .scrollIndicators(.visible)
        }
    }

    private func companyRow(_ company: CompanyPlaceholder) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 42, height: 42)

                Image(systemName: company.logoSystemName)
                    .foregroundColor(.blue)
            }

            Text(company.name)
                .font(.headline)

            Spacer()

            Link(destination: company.websiteURL) {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }

            Button {
                openURL(company.phoneURL)
            } label: {
                Image(systemName: "phone.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }

    private var floatingBottomActions: some View {
        VStack(spacing: 10) {
            Button {
                viewModel.saveEstimate()
            } label: {
                Text("Сохранить")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 45)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.blue)
                    )
            }
            .buttonStyle(.plain)

            HStack(spacing: 12) {
                Button {
                    if viewModel.canOpenSavedEstimates {
                        viewModel.openSavedEstimates()
                    }
                } label: {
                    Text("Сметы")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 45)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(viewModel.canOpenSavedEstimates ? Color.blue : Color(.systemGray5))
                        )
                }
                .buttonStyle(.plain)
                .allowsHitTesting(viewModel.canOpenSavedEstimates)

                Button {
                    viewModel.startNewCalculation()
                } label: {
                    Text("Рассчитать заново")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 45)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color.red)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
}
