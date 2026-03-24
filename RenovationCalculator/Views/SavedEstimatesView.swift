import SwiftUI

struct SavedEstimatesView: View {
    @EnvironmentObject private var store: SavedEstimatesStore
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if store.isLoading && store.estimates.isEmpty {
                    ProgressView("Загрузка смет...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if store.estimates.isEmpty {
                    VStack(spacing: 12) {
                        Text("Сохраненных смет пока нет")
                            .foregroundColor(.secondary)
                        Button("Сделать новый расчет") {
                            router.show(.rooms, resetViewTree: true)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(store.estimates) { estimate in
                            NavigationLink {
                                SavedEstimateDetailView(estimate: estimate)
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(formattedDate(estimate.createdAt))
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
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    store.delete(id: estimate.id)
                                    if !store.hasSavedEstimates {
                                        router.rootScreen = .rooms
                                    }
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)

                    Button("Сделать новый расчет") {
                        router.show(.rooms, resetViewTree: true)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
            .navigationTitle("Сохраненные сметы")
            .onAppear {
                store.reload()
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
                    }
                }
                .listStyle(.plain)
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
        .navigationTitle("Смета")
        .navigationBarTitleDisplayMode(.inline)
    }
}
