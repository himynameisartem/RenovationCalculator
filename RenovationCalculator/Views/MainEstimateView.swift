import SwiftUI

struct MainEstimateView: View {
    @StateObject private var vm: MainEstimateViewModel
    @State private var expandedSectionIDs: Set<String> = []
    @State private var showFinal = false
    @State private var quantitySheetDetent: PresentationDetent = .fraction(0.5)

    init(rooms: [RoomInput]) {
        _vm = StateObject(wrappedValue: MainEstimateViewModel(rooms: rooms))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if vm.categories.isEmpty {
                    Text("Нет данных")
                        .foregroundColor(.secondary)
                        .padding(.top, 40)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(vm.categories.indices, id: \.self) { i in
                                    let category = vm.categories[i]
                                    let selected = i == vm.selectedCategoryIndex

                                    Button(category.title) {
                                        vm.selectedCategoryIndex = i
                                        withAnimation {
                                            proxy.scrollTo(category.id, anchor: .center)
                                        }
                                    }
                                    .id(category.id)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(selected ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selected ? .white : .primary)
                                    .clipShape(Capsule())
                                }
                            }
                            .padding()
                        }
                        .onChange(of: vm.selectedCategoryIndex) { _, newIndex in
                            guard vm.categories.indices.contains(newIndex) else { return }
                            let id = vm.categories[newIndex].id
                            withAnimation {
                                proxy.scrollTo(id, anchor: .center)
                            }
                        }
                    }
                }

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
                                                    .imageScale(.large)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)

                                            Text("\(item.price, specifier: "%.0f") ₽ / \(item.unit)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.center)

                                            Spacer()
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
                                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 12))
                            }
                        }
                    }
                }
                .onChange(of: vm.selectedCategoryIndex) { _, _ in
                    expandedSectionIDs.removeAll()
                }

                if vm.hasAnySelected() && vm.infoItem == nil {
                    Button {
                        vm.isSummarySheetPresented = true
                    } label: {
                        Text("Сумма: \(vm.totalSum(), specifier: "%.0f") ₽")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding([.horizontal, .top])
                }

                if vm.infoItem == nil {
                    HStack {
                        Button("Далее") {
                            if vm.selectedCategoryIndex + 1 < vm.categories.count {
                                vm.selectedCategoryIndex += 1
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(vm.isLastCategory() || !vm.hasSelectedInCurrentCategory())

                        Spacer()

                        Button("Завершить") {
                            showFinal = true
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!vm.hasAnySelected())
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                }
            }
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
                                Image(name)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(12)
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
        .navigationDestination(isPresented: $showFinal) {
            FinalEstimateView(
                lines: vm.summaryLines(),
                total: vm.totalSum(),
                onReset: { vm.resetAll() },
                onSave: { _ = vm.saveEstimate() }
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
}
