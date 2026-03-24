import SwiftUI

struct MainEstimateView: View {
    private let categoryOverlayHeight: CGFloat = 50

    @StateObject private var vm: MainEstimateViewModel
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var store: SavedEstimatesStore
    @EnvironmentObject private var router: AppRouter
    @State private var expandedSectionIDs: Set<String> = []
    @State private var showFinal = false
    @State private var quantitySheetDetent: PresentationDetent = .fraction(0.5)

    init(rooms: [RoomInput], initialSelectedItems: [String: Double] = [:], editingEstimateID: UUID? = nil) {
        _vm = StateObject(
            wrappedValue: MainEstimateViewModel(
                rooms: rooms,
                initialSelectedItems: initialSelectedItems,
                editingEstimateID: editingEstimateID
            )
        )
    }

    var body: some View {
        ZStack {
            content
                .onAppear { vm.load() }

            if let item = vm.infoItem {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture { vm.infoItem = nil }

                VStack(spacing: 12) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundColor(.white)

                    if let photos = item.photos, !photos.isEmpty {
                        TabView {
                            ForEach(photos, id: \.self) { name in
                                EstimatePhotoView(source: name)
                                    .padding(.horizontal)
                            }
                        }
                        .frame(height: 260)
                        .tabViewStyle(.page)
                    } else {
                        Text("Фото нет")
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding()
            }
        }
        .appScreenBackground()
        .navigationDestination(isPresented: $showFinal) {
            FinalEstimateView(
                lines: vm.summaryLines(),
                total: vm.totalSum(),
                store: store,
                router: router,
                onReset: { vm.resetAll() },
                onSave: { vm.saveEstimate() }
            )
        }
        .sheet(isPresented: $vm.isQuantitySheetPresented) {
            if let item = vm.quantityItem {
                QuantitySheet(item: item, rooms: vm.roomOptions) { qty in
                    vm.addItem(item, quantity: qty)
                }
                .presentationDetents([.fraction(0.5), .large], selection: $quantitySheetDetent)
                .presentationDragIndicator(.visible)
            } else {
                Text("Нет данных")
            }
        }
        .sheet(isPresented: $vm.isSummarySheetPresented) {
            SummarySheet(
                lines: vm.summaryLines(),
                total: vm.totalSum(),
                onRemove: { id in vm.removeItem(id: id) },
                onReset: { vm.resetAll() }
            )
            .presentationDetents([.medium, .large])
        }
        .onChange(of: vm.isQuantitySheetPresented) { _, isPresented in
            guard isPresented else {
                quantitySheetDetent = .fraction(0.5)
                return
            }
            quantitySheetDetent = vm.roomOptions.count > 4 ? .large : .fraction(0.5)
        }
    }

    @ViewBuilder
    private var content: some View {
        if vm.isLoading && vm.categories.isEmpty {
            ProgressView("Загрузка каталога...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if vm.categories.isEmpty {
            Text("Нет данных")
                .foregroundColor(.secondary)
                .padding(.top, 40)
        } else {
            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    List {
                        ForEach(vm.currentSections) { section in
                            DisclosureGroup(
                                section.title,
                                isExpanded: Binding(
                                    get: { expandedSectionIDs.contains(section.id) },
                                    set: { isExpanded in
                                        if isExpanded { expandedSectionIDs.insert(section.id) }
                                        else { expandedSectionIDs.remove(section.id) }
                                    }
                                )
                            ) {
                                ForEach(section.items) { item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.title)
                                                .padding(.vertical, 8)
                                            HStack {
                                                Button(action: { vm.showInfo(item) }) {
                                                    Image(systemName: "info.circle")
                                                        .imageScale(.medium)
                                                }
                                                .buttonStyle(.plain)

                                                Spacer()

                                                Text("\(item.price, specifier: "%.0f") ₽ / \(item.unit)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .multilineTextAlignment(.trailing)
                                            }
                                        }
                                        .padding(.vertical, 4)

                                        Spacer()

                                        Button(action: { vm.showQuantity(item) }) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 48))
                                        }
                                        .buttonStyle(.plain)
                                        .foregroundColor(.blue)
                                        .padding(.leading, 20)
                                    }
                                    .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 8))
                                    .appListCardBackground()
                                }
                            }
                            .appListCardBackground()
                        }
                    }
                    .padding(.top, categoryOverlayHeight)
                    .transparentListContent()
                    .onChange(of: vm.selectedCategoryIndex) { _, _ in
                        expandedSectionIDs.removeAll()
                    }
                    .safeAreaInset(edge: .bottom) {
                        Color.clear
                            .frame(height: vm.hasAnySelected() ? 130 : 72)
                    }

                }
                .overlay(alignment: .top) {
                    categoryGlassBar(proxy: proxy)
                }
                .overlay(alignment: .bottom) {
                    if vm.infoItem == nil {
                        floatingBottomActions
                    }
                }
                .onChange(of: vm.selectedCategoryIndex) { _, newIndex in
                    guard vm.categories.indices.contains(newIndex) else { return }
                    let id = vm.categories[newIndex].id
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }

    private var floatingBottomActions: some View {
        VStack(spacing: 10) {
            if vm.hasAnySelected() {
                Button {
                    vm.isSummarySheetPresented = true
                } label: {
                    Text("Сумма: \(vm.totalSum(), specifier: "%.0f") ₽")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 30)
                }
                .buttonStyle(.borderedProminent)
            }
            
            HStack(spacing: 12) {
                let isNextDisabled = vm.isLastCategory() || !vm.hasSelectedInCurrentCategory()
                let isFinishDisabled = !vm.hasAnySelected()
                
                Button {
                    if !isNextDisabled, vm.selectedCategoryIndex + 1 < vm.categories.count {
                        vm.selectedCategoryIndex += 1
                    }
                } label: {
                    Text("Далее")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 45)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(isNextDisabled ? Color(.systemGray5) : Color.blue)
                        )
                }
                .buttonStyle(.plain)
                .allowsHitTesting(!isNextDisabled)
                
                Button {
                    if !isFinishDisabled {
                        showFinal = true
                    }
                } label: {
                    Text("Завершить")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 45)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(isFinishDisabled ? Color(.systemGray5) : Color.red)
                        )
                }
                .buttonStyle(.plain)
                .allowsHitTesting(!isFinishDisabled)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var categoryGlassFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.white.opacity(0.55)
    }

    private var categoryGlassStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.14) : Color.white.opacity(0.55)
    }

    private var categoryCapsuleFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.35)
    }

    private var categoryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.92) : .primary
    }

    private func categoryGlassBar(proxy: ScrollViewProxy) -> some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(categoryGlassFill)
                .background(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(categoryGlassStroke, lineWidth: 1)
                }
                .frame(height: 86)
                .mask(
                    VStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .frame(height: 60)

                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .frame(height: 26)
                            .blur(radius: 10)
                            .mask(
                                LinearGradient(
                                    colors: [.black.opacity(0.9), .black.opacity(0.45), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                )
                .shadow(color: Color.black.opacity(0.08), radius: 20, y: 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(vm.categories.indices, id: \.self) { i in
                        let category = vm.categories[i]
                        let selected = i == vm.selectedCategoryIndex

                        Button(category.title) {
                            vm.selectedCategoryIndex = i
                            withAnimation(.easeInOut(duration: 0.25)) {
                                proxy.scrollTo(category.id, anchor: .center)
                            }
                        }
                        .id(category.id)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            selected
                                ? AnyView(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.9))
                                )
                                : AnyView(
                                    Capsule()
                                        .fill(categoryCapsuleFill)
                                )
                        )
                        .foregroundColor(selected ? .white : categoryTextColor)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .clipShape(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .inset(by: 2)
            )
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .frame(height: categoryOverlayHeight, alignment: .top)
        .allowsHitTesting(true)
        .compositingGroup()
    }
}

private struct EstimatePhotoView: View {
    let source: String

    var body: some View {
        if let url = URL(string: source), url.scheme?.hasPrefix("http") == true {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.15))
                        ProgressView()
                    }
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                case .failure:
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.15))
                        Text("Фото не загрузилось")
                            .foregroundColor(.secondary)
                    }
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            Image(source)
                .resizable()
                .scaledToFit()
                .cornerRadius(12)
        }
    }
}
