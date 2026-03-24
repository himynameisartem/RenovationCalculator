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
                        .appListCardBackground()
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    }
                }
                .transparentListContent()
//                .safeAreaInset(edge: .bottom) {
//                    Color.clear
//                        .frame(height: 130)
//                }
            }

            Text("Итого: \(total, specifier: "%.0f") ₽")
                .font(.title3)
                .padding(.top, 4)
        }
        .padding(.bottom, 130)
        .appScreenBackground()
        .overlay(alignment: .bottom) {
            floatingBottomActions
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
