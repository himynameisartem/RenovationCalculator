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

    var body: some View {
        VStack(spacing: 12) {
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
                    .frame(maxHeight: 260)
                    .scrollIndicators(.visible)
                    .padding(.horizontal, 16)
                }
            }

            Spacer(minLength: 0)

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
                    Image(systemName: "info.circle")
                }
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
            .frame(maxWidth: 280, alignment: .leading)
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
}
