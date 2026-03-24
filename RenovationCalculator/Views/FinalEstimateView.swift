import SwiftUI

struct FinalEstimateView: View {
    @EnvironmentObject private var store: SavedEstimatesStore
    @EnvironmentObject private var router: AppRouter

    let lines: [MainEstimateViewModel.SummaryLine]
    let total: Double
    let onReset: () -> Void
    let onSave: () -> String

    @State private var showResetAlert = false
    @State private var showSaveAlert = false
    @State private var saveMessage = ""
    @State private var isSaved = false

    var body: some View {
        VStack(spacing: 12) {
            Text("Смета")
                .font(.headline)

            if lines.isEmpty {
                Text("Смета пустая")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            } else {
                List {
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
                    }
                }
                .listStyle(.plain)
            }

            Text("Итого: \(total, specifier: "%.0f") ₽")
                .font(.title3)
                .padding(.top, 4)

            VStack(spacing: 10) {
                Button("Сохранить") {
                    saveMessage = onSave()
                    store.reload()
                    isSaved = !saveMessage.lowercased().contains("ошибка")
                    showSaveAlert = true
                }
                .buttonStyle(.borderedProminent)

                Button("Сметы") {
                    store.reload()
                    router.show(.savedEstimates, resetViewTree: true)
                }
                .buttonStyle(.bordered)
                .disabled(store.estimates.isEmpty && !isSaved)

                Button("Рассчитать заново") {
                    if isSaved {
                        router.show(.rooms, resetViewTree: true)
                    } else {
                        showResetAlert = true
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding(.bottom, 12)
        }
        .alert("Уверены?", isPresented: $showResetAlert) {
            Button("Да, сбросить", role: .destructive) {
                onReset()
                router.show(.rooms, resetViewTree: true)
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Если смета не сохранена, все расчеты будут удалены.")
        }
        .alert("Сохранение", isPresented: $showSaveAlert) {
            Button("Ок", role: .cancel) { }
        } message: {
            Text(saveMessage)
        }
    }
}
