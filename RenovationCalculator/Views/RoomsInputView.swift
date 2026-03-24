import SwiftUI
import Combine

struct RoomsInputView: View {
    @StateObject private var vm: RoomsInputViewModel
    @StateObject private var keyboard = KeyboardObserver()

    init(viewModel: RoomsInputViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
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
                .navigationTitle("Комнаты")
                .navigationDestination(isPresented: $vm.goNext) {
                    MainEstimateView(rooms: vm.rooms)
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Готово") { hideKeyboard() }
                    }
                }
            }

            if !vm.goNext {
                floatingBottomActions
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }

            if keyboard.isVisible {
                keyboardDoneButton
            }
        }
        .appScreenBackground()
        .ignoresSafeArea(.keyboard, edges: .bottom)
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

    private var keyboardDoneButton: some View {
        HStack {
            Spacer()

            Button("Готово") {
                hideKeyboard()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .frame(height: 40)
            .background(
                Capsule()
                    .fill(Color.blue)
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, keyboard.visibleHeight + 6)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: keyboard.isVisible)
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

@MainActor
private final class KeyboardObserver: ObservableObject {
    @Published var height: CGFloat = 0

    private var cancellables = Set<AnyCancellable>()

    var isVisible: Bool {
        height > 0
    }

    var visibleHeight: CGFloat {
        max(0, height - safeAreaBottomInset)
    }

    init() {
        let willShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification -> CGFloat? in
                guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return nil
                }
                return frame.height
            }

        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat.zero }

        willShow
            .merge(with: willHide)
            .receive(on: RunLoop.main)
            .assign(to: &$height)
    }

    private var safeAreaBottomInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: \.isKeyWindow)?
            .safeAreaInsets.bottom ?? 0
    }
}
