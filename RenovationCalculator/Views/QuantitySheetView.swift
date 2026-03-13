import SwiftUI

struct RoomOption: Identifiable, Hashable {
    let id: UUID
    var name: String
    var isSelected: Bool
}

struct QuantitySheet: View {
    let item: WorkItem
    let rooms: [RoomOption]

    @State private var quantity: Double = 1
    @State private var localRooms: [RoomOption] = []

    @Environment(\.dismiss) private var dismiss

    var subtotal: Double { quantity * item.price }

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

            VStack(alignment: .leading, spacing: 8) {
                Text("Количество комнат:")
                    .font(.subheadline)

                if localRooms.isEmpty {
                    Text("Комнаты не выбраны")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    ForEach($localRooms) { $room in
                        Toggle(room.name, isOn: $room.isSelected)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            HStack {
                Button("Отмена") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Добавить") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .onAppear {
            localRooms = rooms
        }
    }
}
