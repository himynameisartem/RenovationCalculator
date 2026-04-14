import SwiftUI

struct RoomOption: Identifiable, Hashable {
    let id: UUID
    var name: String
    var area: Double
    var isSelected: Bool
}

struct QuantitySheet: View {
    let item: WorkItem
    let rooms: [RoomOption]
    let onAdd: (Double) -> Void

    @State private var quantity: Double = 1
    @State private var localRooms: [RoomOption] = []

    @Environment(\.dismiss) private var dismiss

    private var isAreaUnit: Bool {
        let unit = item.unit.lowercased()
        return unit.contains("кв") || unit.contains("м2")
    }

    private var subtotal: Double { quantity * item.price }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 10) {
                Text(item.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("\(item.price, specifier: "%.0f") ₽ / \(item.unit)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    Button {
                        if quantity > 0 { quantity -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 28))
                    }

                    TextField("0", value: $quantity, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 100)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        quantity += 1
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                    }
                }

                Text("Сумма: \(subtotal, specifier: "%.0f") ₽")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Комнаты:")
                        .font(.subheadline)

                    if localRooms.isEmpty {
                        Text("Комнаты не выбраны")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    } else {
                        ForEach($localRooms) { $room in
                            HStack(spacing: 12) {
                                Text(room.name)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("\(room.area, specifier: "%.1f") м²")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 72, alignment: .trailing)

                                Toggle("", isOn: $room.isSelected)
                                    .labelsHidden()
                                    .disabled(!isAreaUnit)
                                    .frame(width: 52, alignment: .trailing)
                            }
                            .opacity(isAreaUnit ? 1 : 0.4)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Button("Отмена") { dismiss() }
                    .buttonStyle(.bordered)

                Spacer()

                Button("Добавить") {
                    onAdd(quantity)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .onAppear {
            localRooms = rooms
            if isAreaUnit {
                quantity = selectedArea()
            }
        }
        .onChange(of: localRooms) { _, _ in
            if isAreaUnit {
                quantity = selectedArea()
            }
        }
    }

    private func selectedArea() -> Double {
        localRooms.filter { $0.isSelected }.reduce(0) { $0 + $1.area }
    }
}
