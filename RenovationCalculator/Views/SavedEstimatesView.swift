import SwiftUI

struct SavedEstimatesView: View {
    @ObservedObject var viewModel: SavedEstimatesViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isLoading && !viewModel.hasEstimates {
                    ProgressView("Загрузка смет...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !viewModel.hasEstimates {
                    VStack(spacing: 12) {
                        Text("Сохраненных смет пока нет")
                            .foregroundColor(.secondary)
                        Button {
                            viewModel.showNewEstimate()
                        } label: {
                            Text("Сделать новый расчет")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.blue)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.estimates) { estimate in
                            NavigationLink {
                                SavedEstimateDetailView(estimate: estimate)
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(viewModel.formattedDate(estimate.createdAt))
                                            .font(.headline)
                                        Spacer()
                                        Text("\(estimate.total, specifier: "%.0f") ₽")
                                            .font(.headline)
                                    }

                                    Text("\(estimate.lines.count) поз.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    ForEach(estimate.lines.prefix(3)) { line in
                                        HStack {
                                            Text(line.title)
                                                .lineLimit(1)
                                            Spacer()
                                            Text("\(line.subtotal, specifier: "%.0f") ₽")
                                                .foregroundColor(.secondary)
                                        }
                                        .font(.caption)
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                            .appListCardBackground()
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.deleteEstimate(estimate)
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .transparentListContent()

                    Button {
                        viewModel.showNewEstimate()
                    } label: {
                        Text("Сделать новый расчет")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 45)
                            .background(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(Color.blue)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .appScreenBackground()
            .navigationTitle("Сохраненные сметы")
            .onAppear {
                viewModel.onAppear()
            }
        }
    }
}

private struct SavedEstimateDetailView: View {
    @Environment(\.openURL) private var openURL
    @State private var isInfoHintVisible = false
    @State private var isManualInfoHint = false
    @State private var didShowInitialInfoHint = false
    let estimate: SavedEstimate
    private let infoBubbleHorizontalInset: CGFloat = 16

    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Список компаний")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)

                Text("Ниже приведены примеры компаний для ориентира. Вы можете выбрать любую другую компанию или подрядчика по своему усмотрению.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
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
                    .padding(.horizontal, 16)

                if estimate.lines.isEmpty {
                    Text("Смета пустая")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        )
                        .padding(.horizontal, 16)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(estimate.lines) { line in
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .scrollIndicators(.visible)
                    .padding(.horizontal, 16)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            Text("Итого: \(estimate.total, specifier: "%.0f") ₽")
                .font(.title3)

            NavigationLink {
                MainEstimateView(
                    rooms: estimate.rooms,
                    initialSelectedItems: estimate.selectedItems,
                    editingEstimateID: estimate.id
                )
            } label: {
                Text("Изменить")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 45)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.blue)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
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
                Color.black.opacity(0.14)
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
        .navigationTitle("Смета")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var placeholderCompanies: [CompanyPlaceholder] {
        [
            CompanyPlaceholder(
                name: "ГК Поколение",
                logoName: "pokolenieLogo",
                websiteURL: URL(string: "https://gkpokolenie.ru")!,
                phoneURL: URL(string: "tel:+79581005418")!
            ),
            CompanyPlaceholder(
                name: "Легион",
                logoName: "legionLogo",
                websiteURL: URL(string: "https://legionremont.ru")!,
                phoneURL: URL(string: "tel:+79158303600")!
            ),
            CompanyPlaceholder(
                name: "СК Фемели",
                logoName: "femeliLogo",
                websiteURL: URL(string: "https://skfamily.moscow")!,
                phoneURL: URL(string: "tel:+79158303600")!
            )
        ]
    }

    private struct CompanyPlaceholder: Identifiable {
        let id = UUID()
        let name: String
        let logoName: String
        let websiteURL: URL
        let phoneURL: URL
    }

    private var infoHintBubble: some View {
        VStack(alignment: .trailing, spacing: 0) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .frame(width: 16, height: 16)
                .rotationEffect(.degrees(45))
                .padding(.trailing, 28)
                .padding(.bottom, -8)

            VStack(alignment: .leading, spacing: 10) {
                Text("Указанные компании приведены в качестве примеров и не ограничивают ваш выбор подрядчика. Итоговая стоимость, сроки и условия работ уточняются напрямую у выбранной компании. Информация на экране носит ознакомительный характер и не является публичной офертой.")
                    .font(.footnote)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }
            .padding(10)
            .frame(maxWidth: min(UIScreen.main.bounds.width - (infoBubbleHorizontalInset * 2), 320), alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
            .shadow(color: Color.black.opacity(0.08), radius: 12, y: 6)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func companyRow(_ company: CompanyPlaceholder) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 42, height: 42)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )

                Image(company.logoName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
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
}
