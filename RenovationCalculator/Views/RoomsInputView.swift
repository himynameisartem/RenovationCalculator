import SwiftUI

struct RoomsInputView: View {
    @StateObject private var vm = RoomsInputViewModel()
    
    var isContinueButtonEnabled: Bool {
        return vm.livingCount > 0 ||
               vm.kitchenCount > 0 ||
               vm.bathroomCount > 0 ||
               vm.hallwayCount > 0
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    Section {
                        Text("Укажите количество комнат и их параметры. Окна стандартные по размеру.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }

                    Section("Комнаты") {
                        RoomTypeRow(
                            title: "Жилая",
                            count: $vm.livingCount,
                            totalCount: vm.count(for: .living),
                            rooms: vm.rooms(for: .living),
                            onChange: vm.updateRoom
                        )
                        RoomTypeRow(
                            title: "Кухня",
                            count: $vm.kitchenCount,
                            totalCount: vm.count(for: .kitchen),
                            rooms: vm.rooms(for: .kitchen),
                            onChange: vm.updateRoom
                        )
                        RoomTypeRow(
                            title: "Санузел",
                            count: $vm.bathroomCount,
                            totalCount: vm.count(for: .bathroom),
                            rooms: vm.rooms(for: .bathroom),
                            onChange: vm.updateRoom
                        )
                        RoomTypeRow(
                            title: "Прихожая",
                            count: $vm.hallwayCount,
                            totalCount: vm.count(for: .hallway),
                            rooms: vm.rooms(for: .hallway),
                            onChange: vm.updateRoom
                        )
                    }
                    Text("Площадь квартиры: \(vm.totalArea(), specifier: "%.1f") м²")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                }
                .ignoresSafeArea(edges: .bottom)
                .listStyle(.insetGrouped)
                .onTapGesture {
                    hideKeyboard()
                }


                HStack{
                    Button("Пропустить") {
                        // позже тут можно сбросить данные или перейти дальше
                        
                    }
                    .foregroundColor(.black.opacity(0.7))
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .padding(.horizontal, 20)
                        .tint(.gray)
                    Spacer()
                    

                    Button("Продолжить") {
                        // переход на следующий экран
                    }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.horizontal, 20)
                        .tint(.blue)
                        .disabled(!isContinueButtonEnabled)
                        .opacity(isContinueButtonEnabled ? 1 : 0.7)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .navigationTitle("Комнаты")
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") { hideKeyboard() }
            }
        }
    }
}

private struct RoomTypeRow: View {
    let title: String
    @Binding var count: Int
    let totalCount: Int
    let rooms: [RoomInput]
    let onChange: (RoomInput) -> Void

    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(rooms) { room in
                RoomParamsView(room: room, onChange: onChange)
                    .padding(.vertical, 4)
            }
        } label: {
            HStack {
                Text(title)
                if totalCount > 0 {
                    Text("\(totalCount)")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .clipShape(Capsule())
                }
                Spacer()
                Stepper(value: $count, in: 0...10) {
                    Text("\(count)")
                }
                .labelsHidden()
            }
        }
        .onChange(of: count) { _, _ in
            if count > 0 { isExpanded = true }
            if count == 0 { isExpanded = false }
        }
    }
}

private struct RoomParamsView: View {
    @State var room: RoomInput
    let onChange: (RoomInput) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            TextField("Название комнаты", text: $room.name)
                .font(.system(size: 18, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.vertical, 8)

            HStack {
                Text("Площадь")
                Spacer()
                TextField("м2", value: $room.area, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .padding(6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                    .frame(width: 60)
                Text("м2")
            }

            HStack {
                Text("Высота")
                Spacer()
                TextField("м", value: $room.height, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .padding(6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                    .frame(width: 60)
                Text(" м ")
            }

            Stepper("Окна: \(room.windows)", value: $room.windows, in: 0...10)
                .padding(.vertical, 8)
        }
        .onChange(of: room) { _, updated in
            onChange(updated)
        }
    }
}

#Preview {
    RoomsInputView()
}
