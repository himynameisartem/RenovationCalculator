import SwiftUI
import Combine

struct RoomsInputView: View {
    @EnvironmentObject private var store: SavedEstimatesStore
    @EnvironmentObject private var router: AppRouter
    @StateObject private var vm: RoomsInputViewModel
    @StateObject private var keyboard = KeyboardObserver()

    init(viewModel: RoomsInputViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack {
                VStack(spacing: 0) {
                    stepsBar
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Укажите помещения")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.primary)

                                Text("Выберите количество комнат и их\nпараметров или продолжите без них.")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                            // Карточка комнат
                            VStack(spacing: 0) {
                                RoomTypeRow(
                                    title: "Жилые комнаты",
                                    icon: "sofa",
                                    iconColor: Color(red: 91/255, green: 147/255, blue: 234/255),
                                    iconBg: Color(red: 91/255, green: 147/255, blue: 234/255).opacity(0.12),
                                    count: $vm.livingCount,
                                    totalCount: vm.count(for: .living),
                                    roomIndices: vm.roomsIndices(for: .living),
                                    rooms: $vm.rooms
                                )
                                Divider().padding(.leading, 64)
                                RoomTypeRow(
                                    title: "Кухня",
                                    icon: "refrigerator",
                                    iconColor: Color(red: 76/255, green: 175/255, blue: 110/255),
                                    iconBg: Color(red: 76/255, green: 175/255, blue: 110/255).opacity(0.12),
                                    count: $vm.kitchenCount,
                                    totalCount: vm.count(for: .kitchen),
                                    roomIndices: vm.roomsIndices(for: .kitchen),
                                    rooms: $vm.rooms
                                )
                                Divider().padding(.leading, 64)
                                RoomTypeRow(
                                    title: "Гостиная",
                                    icon: "tv",
                                    iconColor: Color(red: 224/255, green: 122/255, blue: 78/255),
                                    iconBg: Color(red: 224/255, green: 122/255, blue: 78/255).opacity(0.12),
                                    count: $vm.hallwayCount,
                                    totalCount: vm.count(for: .hallway),
                                    roomIndices: vm.roomsIndices(for: .hallway),
                                    rooms: $vm.rooms
                                )
                                Divider().padding(.leading, 64)
                                RoomTypeRow(
                                    title: "Санузел",
                                    icon: "shower",
                                    iconColor: Color(red: 130/255, green: 100/255, blue: 200/255),
                                    iconBg: Color(red: 130/255, green: 100/255, blue: 200/255).opacity(0.12),
                                    count: $vm.bathroomCount,
                                    totalCount: vm.count(for: .bathroom),
                                    roomIndices: vm.roomsIndices(for: .bathroom),
                                    rooms: $vm.rooms
                                )
                            }
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
                            .padding(.horizontal, 16)

                            // Карточка общей площади
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(red: 91/255, green: 147/255, blue: 234/255).opacity(0.12))
                                        .frame(width: 48, height: 48)
                                    Image(systemName: "square.split.bottomrightquarter")
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundColor(Color(red: 91/255, green: 147/255, blue: 234/255))
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Общая площадь:")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.secondary)
                                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                                        Text(vm.totalArea() > 0 ? String(format: "%.1f", vm.totalArea()) : "0")
                                            .font(.system(size: 26, weight: .bold))
                                            .foregroundColor(.primary)
                                        Text("м²")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
                            .padding(.horizontal, 16)
                        }
                        .padding(.bottom, vm.canOpenSavedEstimates ? 160 : 110)
                    }
                    .onTapGesture { hideKeyboard() }
                }
                .background(Color(UIColor.systemGroupedBackground))
                .navigationTitle("Калькулятор")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(isPresented: $vm.goNext) {
                    MainEstimateView(rooms: vm.rooms)
                        .environmentObject(store)
                        .environmentObject(router)
                }
            }

            if !vm.goNext {
                bottomActions
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }

            if keyboard.isVisible {
                keyboardDoneButton
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    // MARK: - Steps Bar

    private var stepsBar: some View {
        HStack(spacing: 10) {
            StepItem(
                number: 1,
                label: "Помещения",
                state: .active
            )
            
            StepItem(
                number: 2,
                label: "Работы",
                state: .inactive
            )
            
            StepItem(
                number: 3,
                label: "Итог",
                state: .inactive
            )
        }
    }

    private var stepLine: some View {
        EmptyView()
    }

    private enum StepState {
        case active
        case inactive
    }

    private struct StepItem: View {
        let number: Int
        let label: String
        let state: StepState
        
        var body: some View {
            HStack(spacing: 8) {
                
                Circle()
                    .fill(
                        state == .active
                        ? Color.blue
                        : Color(.systemGray4)
                    )
                    .frame(width: 28, height: 28)
                    .overlay {
                        Text("\(number)")
                            .font(.caption.bold())
                            .foregroundColor(
                                state == .active
                                ? .white
                                : .black
                            )
                    }
                
                Text(label)
                    .font(.caption.bold())
                    .foregroundColor(
                        state == .active
                        ? .blue
                        : .gray
                    )
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Bottom Actions

    private var bottomActions: some View {
            HStack(spacing: 12) {
                Button { vm.skip() } label: {
                    Text("Пропустить")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.blue))
                }
                .buttonStyle(.plain)

                Button {
                    if vm.isContinueButtonEnabled { vm.continueToEstimate() }
                } label: {
                    Text("Продолжить")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(vm.isContinueButtonEnabled ? .white : Color(UIColor.systemGray3))
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(vm.isContinueButtonEnabled ? Color.blue : Color(UIColor.systemGray5))
                        )
                }
                .buttonStyle(.plain)
                .allowsHitTesting(vm.isContinueButtonEnabled)
            }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .padding(.top, 8)
    }

    // MARK: - Keyboard Done

    private var keyboardDoneButton: some View {
        HStack {
            Spacer()
            Button("Готово") { hideKeyboard() }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .frame(height: 40)
                .background(Capsule().fill(Color.blue))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, keyboard.visibleHeight + 6)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: keyboard.isVisible)
    }
}

// MARK: - StepItem

private struct StepItem: View {
    let number: Int
    let label: String
    let isActive: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isActive ? Color.blue : Color(UIColor.systemGray5))
                    .frame(width: 28, height: 28)
                Text("\(number)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isActive ? .white : Color(UIColor.systemGray2))
            }
            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(isActive ? .blue : Color(UIColor.systemGray2))
        }
    }
}

// MARK: - RoomTypeRow

private struct RoomTypeRow: View {
    let title: String
    let icon: String
    let iconColor: Color
    let iconBg: Color
    @Binding var count: Int
    let totalCount: Int
    let roomIndices: [Int]
    @Binding var rooms: [RoomInput]

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(iconBg)
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(iconColor)
                }

                Text(title)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary)

                Spacer()

                HStack(spacing: 0) {
                    Button {
                        if count > 0 { count -= 1 }
                    } label: {
                        Text("−")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(count > 0 ? .primary : Color(UIColor.systemGray3))
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)

                    Rectangle()
                        .fill(Color(UIColor.systemGray4))
                        .frame(width: 1, height: 20)

                    Button {
                        count += 1
                    } label: {
                        Text("+")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                }
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                )

                Image(systemName: count > 0 && isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(count > 0 ? Color(UIColor.systemGray3) : Color(UIColor.systemGray4))
                    .onTapGesture {
                        if count > 0 { withAnimation { isExpanded.toggle() } }
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            if isExpanded && count > 0 {
                VStack(spacing: 0) {
                    Divider().padding(.leading, 16)
                    ForEach(roomIndices, id: \.self) { idx in
                        RoomParamsView(room: $rooms[idx])
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        if idx != roomIndices.last {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onChange(of: count) { _, _ in
            withAnimation(.spring(response: 0.3)) {
                isExpanded = count > 0
            }
        }
    }
}

// MARK: - RoomParamsView

private struct RoomParamsView: View {
    @Binding var room: RoomInput

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Название комнаты", text: $room.name)
                .font(.system(size: 16, weight: .semibold))
                .padding(.vertical, 4)

            HStack {
                Text("Площадь").font(.system(size: 14)).foregroundColor(.secondary)
                Spacer()
                TextField("м²", value: $room.area, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8).frame(width: 64)
                Text("м²").font(.system(size: 14)).foregroundColor(.secondary)
            }

            HStack {
                Text("Высота").font(.system(size: 14)).foregroundColor(.secondary)
                Spacer()
                TextField("м", value: $room.height, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8).frame(width: 64)
                Text("м").font(.system(size: 14)).foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - KeyboardObserver

@MainActor
private final class KeyboardObserver: ObservableObject {
    @Published var height: CGFloat = 0
    private var cancellables = Set<AnyCancellable>()

    var isVisible: Bool { height > 0 }
    var visibleHeight: CGFloat { max(0, height - safeAreaBottomInset) }

    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { ($0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height }
            .merge(with:
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                    .map { _ in CGFloat.zero }
            )
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

// MARK: - Preview

#Preview {
    let store = SavedEstimatesStore()
    let router = AppRouter()
    RoomsInputView(
        viewModel: RoomsInputViewModel(
            store: store,
            router: router
        )
    )
    .environmentObject(store)
    .environmentObject(router)
}
