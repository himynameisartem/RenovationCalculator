import SwiftUI

struct SavedEstimatesView: View {
    @ObservedObject var viewModel: SavedEstimatesViewModel

    var body: some View {
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
                            viewModel.destinationView(for: estimate)
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
            }
        }
        .appScreenBackground()
        .navigationTitle("Сохраненные сметы")
        .onAppear {
            viewModel.onAppear()
        }
    }
}
