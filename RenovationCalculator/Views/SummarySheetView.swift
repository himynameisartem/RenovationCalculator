import SwiftUI

struct SummarySheet: View {
    let lines: [EstimateSummaryLine]
    let total: Double
    let onRemove: (String) -> Void
    let onReset: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            Text("Смета")
                .font(.headline)

            if lines.isEmpty {
                Text("Пока ничего не выбрано")
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

                            Button {
                                onRemove(line.itemId)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    }
                }
                .listStyle(.plain)
                .transparentListContent()
            }

            Text("Итого: \(total, specifier: "%.0f") ₽")
                .font(.headline)

            HStack {
                Button("Сбросить все", role: .destructive) {
                    onReset()
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Закрыть") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.clear)
    }
}
