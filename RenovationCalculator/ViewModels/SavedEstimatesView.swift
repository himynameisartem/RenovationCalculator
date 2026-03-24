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
                        Button("Сделать новый расчет") {
                            viewModel.showNewEstimate()
                        }
                        .buttonStyle(.borderedProminent)
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

                    Button("Сделать новый расчет") {
                        viewModel.showNewEstimate()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
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
    let estimate: SavedEstimate

    var body: some View {
        VStack(spacing: 12) {
            if estimate.lines.isEmpty {
                Text("Смета пустая")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            } else {
                List {
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
                        .appListCardBackground()
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    }
                }
                .transparentListContent()
            }

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
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .appScreenBackground()
        .navigationTitle("Смета")
        .navigationBarTitleDisplayMode(.inline)
    }
}
