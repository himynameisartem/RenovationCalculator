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
            Text(item.title)
                .font(.headline)
                .multilineTextAlignment(.center)

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
                .disabled(isAreaUnit)

                TextField("0", value: $quantity, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 100)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isAreaUnit)

                Button {
                    quantity += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                }
                .disabled(isAreaUnit)
            }

            Text("Сумма: \(subtotal, specifier: "%.0f") ₽")
                .font(.headline)

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
                        HStack {
                            Toggle(room.name, isOn: $room.isSelected)
                                .disabled(!isAreaUnit)
                            Spacer()
                            Text("\(room.area, specifier: "%.1f") м²")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .opacity(isAreaUnit ? 1 : 0.4)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

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
