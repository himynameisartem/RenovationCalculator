import SwiftUI

struct MainEstimateView: View {
    
    private let categoryOverlayHeight: CGFloat = 120
    
    @StateObject private var vm: MainEstimateViewModel
    @EnvironmentObject private var store: SavedEstimatesStore
    @EnvironmentObject private var router: AppRouter
    
    @State private var expandedSectionIDs: Set<String> = []
    @State private var showFinal = false
    @State private var quantitySheetDetent: PresentationDetent = .fraction(0.5)
    
    init(
        rooms: [RoomInput],
        initialSelectedItems: [String: Double] = [:],
        editingEstimateID: UUID? = nil
    ) {
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
            Color(.systemGray6).ignoresSafeArea()
            content
                .onAppear { vm.load() }
            
            if let item = vm.infoItem {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture {
                        vm.infoItem = nil
                    }
                
                VStack(spacing: 16) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let photos = item.photos, !photos.isEmpty {
                        TabView {
                            ForEach(photos, id: \.self) { name in
                                EstimatePhotoView(source: name)
                            }
                        }
                        .frame(height: 260)
                        .tabViewStyle(.page)
                    }
                }
                .padding()
            }
        }
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
        .toolbar(.visible, for: .tabBar)
        .sheet(isPresented: $vm.isQuantitySheetPresented) {
            if let item = vm.quantityItem {
                QuantitySheet(item: item, rooms: vm.roomOptions) { qty in
                    vm.addItem(item, quantity: qty)
                }
                .presentationDetents(
                    [.fraction(0.5), .large],
                    selection: $quantitySheetDetent
                )
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
    }
}

// MARK: UI

extension MainEstimateView {
    
    private var content: some View {
        VStack(spacing: 0) {
            topProgressBar
            categoryTabs
            
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(vm.currentSections) { section in
                        sectionCard(section)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 180)
            }
        }
        .overlay(alignment: .bottom) {
            floatingBottomActions
        }
    }
    
    private var topProgressBar: some View {
        HStack(spacing: 10) {
            progressItem(title: "Помещения", number: 1, state: .done)
            progressItem(title: "Работы", number: 2, state: .active)
            progressItem(title: "Итог", number: 3, state: .inactive)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }

    private enum ProgressState {
        case done
        case active
        case inactive
    }

    private func progressItem(title: String, number: Int, state: ProgressState) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(circleColor(state))
                .frame(width: 28, height: 28)
                .overlay {
                    if state == .done {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    } else {
                        Text("\(number)")
                            .font(.caption.bold())
                            .foregroundColor(
                                state == .inactive ? .black : .white
                        )
                    }
                }
            
            Text(title)
                .font(.caption.bold())
                .foregroundColor(textColor(state))
        }
        .frame(maxWidth: .infinity)
    }

    private func circleColor(_ state: ProgressState) -> Color {
        switch state {
        case .done: return .blue
        case .active: return .blue
        case .inactive: return Color(.systemGray4)
        }
    }

    private func textColor(_ state: ProgressState) -> Color {
        switch state {
        case .done: return .blue
        case .active: return .blue
        case .inactive: return .gray
        }
    }
    
    private func categoryIcon(_ category: String) -> Image {
        switch category {
        case  "Демонтажные работы":
            return Image(systemName: "hammer.fill")
        case  "Черновые отделочные работы":
            return Image(systemName: "paintbrush.fill")
        case  "Чистовые отделочные работы":
            return Image(systemName: "level.fill")
        case  "Электромонтажные  работы":
            return Image(systemName: "lightbulb.max.fill")
        case  "Сантехнические  работы":
            return Image(systemName: "spigot.fill")
        case  "Подготовительные  работы":
            return Image(systemName: "wrench.and.screwdriver.fill")
        default:
            return Image(systemName: "hammer.fill")
        }
    }
    
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(vm.categories.indices, id: \.self) { i in
                    
                    let category = vm.categories[i]
                    let selected = i == vm.selectedCategoryIndex
                    
                    Button {
                        vm.selectedCategoryIndex = i
                        expandedSectionIDs.removeAll()
                    } label: {
                        VStack(spacing: 8) {
                            categoryIcon(category.title)
                                .font(.title3)
                            
                            Text(category.title)
                                .font(.caption.bold())
                                .multilineTextAlignment(.center)
                        }
                        .foregroundColor(selected ? .white : .black)
                        .frame(width: 130, height: 82)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    selected
                                    ? Color.blue
                                    : Color.white
                                )
                        )
                        .shadow(
                            color: .black.opacity(0.06),
                            radius: 6,
                            y: 4
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 8)
    }
    
    private func sectionCard(_ section: WorkSection) -> some View {
        
        VStack(spacing: 0) {
            Button {
                if expandedSectionIDs.contains(section.id) {
                    expandedSectionIDs.remove(section.id)
                } else {
                    expandedSectionIDs.insert(section.id)
                }
            } label: {
                HStack {
                    Text(section.title)
                        .font(.headline)
                        .foregroundColor(.black)
                    Spacer()
                    
                    Image(systemName: expandedSectionIDs.contains(section.id) ? "chevron.up" : "chevron.down")
                    .foregroundColor(.gray)
                }
                .padding()
            }
            
            if expandedSectionIDs.contains(section.id) {
                Divider()
                VStack(spacing: 0) {
                    ForEach(section.items) { item in
                        itemRow(item)
                        
                        if item.id != section.items.last?.id {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
        )
        .shadow(
            color: .black.opacity(0.05),
            radius: 10,
            y: 4
        )
    }
    
    private func itemRow(_ item: WorkItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.subheadline)
                    .foregroundColor(.black)
                
                Text("\(item.price, specifier: "%.0f") ₽ / \(item.unit)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            
            Button {
                vm.showQuantity(item)
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 38, height: 38)
                    
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .font(.headline.bold())
                }
            }
        }
        .padding()
    }
    
    private var floatingBottomActions: some View {
        VStack(spacing: 14) {
            
            if vm.hasAnySelected() {
                Button {
                    vm.isSummarySheetPresented = true
                } label: {
                    Text("Сумма: \(vm.totalSum(), specifier: "%.0f") ₽")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 26)
                                .fill(Color.blue)
                        )
                }
            }
            
            HStack(spacing: 14) {
                let nextDisabled = vm.isLastCategory() || !vm.hasSelectedInCurrentCategory()
                let finishDisabled = !vm.hasAnySelected()
                
                // ДАЛЕЕ
                Button {
                    if !nextDisabled {
                        vm.selectedCategoryIndex += 1
                    }
                } label: {
                    Text("Далее")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 26)
                                .fill(
                                    nextDisabled
                                    ? Color(.systemGray4)
                                    : Color.blue
                                )
                        )
                }
                .disabled(nextDisabled)
                
                // ЗАВЕРШИТЬ
                Button {
                    if !finishDisabled {
                        showFinal = true
                    }
                } label: {
                    Text("Завершить")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 26)
                                .fill(
                                    finishDisabled
                                    ? Color(.systemGray4)
                                    : Color.red
                                )
                        )
                }
                .disabled(finishDisabled)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
        .background(
            LinearGradient(
                colors: [.clear, Color(.systemGray6)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

private struct EstimatePhotoView: View {
    let source: String
    
    var body: some View {
        if let url = URL(string: source),
           url.scheme?.hasPrefix("http") == true {
            
            AsyncImage(url: url) { image in
                image.resizable()
                    .scaledToFit()
                    .cornerRadius(14)
            } placeholder: {
                ProgressView()
            }
            
        } else {
            Image(source)
                .resizable()
                .scaledToFit()
                .cornerRadius(14)
        }
    }
}
