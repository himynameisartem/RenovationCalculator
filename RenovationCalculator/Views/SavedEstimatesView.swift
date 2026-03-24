import SwiftUI

struct SavedEstimatesView: View {
    let onNewCalculation: () -> Void
    let onBecomeEmpty: () -> Void

    @State private var estimates: [SavedEstimate] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if estimates.isEmpty {
                    VStack(spacing: 12) {
                        Text("Сохраненных смет пока нет")
                            .foregroundColor(.secondary)
                        Button("Сделать новый расчет") {
                            onNewCalculation()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(estimates) { estimate in
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
                        .onDelete(perform: delete)
                    }
                    .listStyle(.insetGrouped)

                    Button("Сделать новый расчет") {
                        onNewCalculation()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
            .navigationTitle("Сохраненные сметы")
            .onAppear(perform: reload)
        }
    }

    private func reload() {
        estimates = (try? EstimateStorage.loadAll()) ?? []
        if estimates.isEmpty {
            onBecomeEmpty()
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let estimate = estimates[index]
            try? EstimateStorage.delete(id: estimate.id)
        }
        reload()
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
