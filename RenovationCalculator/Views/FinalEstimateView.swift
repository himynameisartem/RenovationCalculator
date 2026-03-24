import SwiftUI

struct FinalEstimateView: View {
    @StateObject private var viewModel: FinalEstimateViewModel
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
                    viewModel.saveEstimate()
                }
                .buttonStyle(.borderedProminent)

                Button("Сметы") {
                    viewModel.openSavedEstimates()
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.canOpenSavedEstimates)

                Button("Рассчитать заново") {
                    viewModel.startNewCalculation()
                }
                .buttonStyle(.bordered)
            }
            .padding(.bottom, 12)
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
}
