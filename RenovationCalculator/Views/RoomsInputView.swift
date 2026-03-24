import SwiftUI

struct RoomsInputView: View {
    @StateObject private var vm: RoomsInputViewModel

    init(viewModel: RoomsInputViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    Section {
                        Text("Укажите количество комнат и их параметры. Окна стандартные по размеру.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .appListCardBackground()
                    }

                    Section("Комнаты") {
                        RoomTypeRow(
                            title: "Жилая",
                            count: $vm.livingCount,
                            totalCount: vm.count(for: .living),
                            roomIndices: vm.roomsIndices(for: .living),
                            rooms: $vm.rooms
                        )
                        RoomTypeRow(
                            title: "Кухня",
                            count: $vm.kitchenCount,
                            totalCount: vm.count(for: .kitchen),
                            roomIndices: vm.roomsIndices(for: .kitchen),
                            rooms: $vm.rooms
                        )
                        RoomTypeRow(
                            title: "Санузел",
                            count: $vm.bathroomCount,
                            totalCount: vm.count(for: .bathroom),
                            roomIndices: vm.roomsIndices(for: .bathroom),
                            rooms: $vm.rooms
                        )
                        RoomTypeRow(
                            title: "Прихожая",
                            count: $vm.hallwayCount,
                            totalCount: vm.count(for: .hallway),
                            roomIndices: vm.roomsIndices(for: .hallway),
                            rooms: $vm.rooms
                        )
                    }

                    Text("Площадь квартиры: \(vm.totalArea(), specifier: "%.1f") м²")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .appListCardBackground()
                }
                .ignoresSafeArea(edges: .bottom)
                .listStyle(.insetGrouped)
                .transparentListContent()
                .safeAreaInset(edge: .bottom) {
                    Color.clear
                        .frame(height: vm.canOpenSavedEstimates ? 130 : 72)
                }
                .onTapGesture { hideKeyboard() }
            }
            .appScreenBackground()
            .overlay(alignment: .bottom) {
                floatingBottomActions
            }
            .navigationTitle("Комнаты")
            .navigationDestination(isPresented: $vm.goNext) {
                MainEstimateView(rooms: vm.rooms)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") { hideKeyboard() }
            }
        }
    }

    private var floatingBottomActions: some View {
        VStack(spacing: 10) {
            if vm.canOpenSavedEstimates {
                Button {
                    vm.openSavedEstimates()
                } label: {
                    Text("Сметы")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 45)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color.blue)
                        )
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                Button {
                    vm.skip()
                } label: {
                    Text("Пропустить")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 45)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color.blue)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    if vm.isContinueButtonEnabled {
                        vm.continueToEstimate()
                    }
                } label: {
                    Text("Продолжить")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 45)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(vm.isContinueButtonEnabled ? Color.blue : Color(.systemGray5))
                        )
                }
                .buttonStyle(.plain)
                .allowsHitTesting(vm.isContinueButtonEnabled)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

private struct RoomTypeRow: View {
    let title: String
    @Binding var count: Int
    let totalCount: Int
    let roomIndices: [Int]
    @Binding var rooms: [RoomInput]

    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(roomIndices, id: \.self) { idx in
                RoomParamsView(room: $rooms[idx])
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
        .appListCardBackground()
        .onChange(of: count) { _, _ in
            if count > 0 { isExpanded = true }
            if count == 0 { isExpanded = false }
        }
    }
}

private struct RoomParamsView: View {
    @Binding var room: RoomInput

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
    }
}

#Preview {
    RoomsInputView(
        viewModel: RoomsInputViewModel(
            store: SavedEstimatesStore(),
            router: AppRouter()
        )
    )
}
