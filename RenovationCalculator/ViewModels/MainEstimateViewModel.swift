import Foundation
import Combine

@MainActor
final class MainEstimateViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var categories: [Category] = []
    @Published var selectedCategoryIndex: Int = 0

    @Published var infoItem: WorkItem?
    @Published var quantityItem: WorkItem?
    @Published var isQuantitySheetPresented: Bool = false
    @Published var isSummarySheetPresented: Bool = false

    @Published var selectedItems: [String: Double] = [:]   // item.id -> quantity

    var roomOptions: [RoomOption] {
        rooms.map { RoomOption(id: $0.id, name: $0.name, area: $0.area, isSelected: false) }
    }

    private let catalogService: CatalogServiceProtocol
    private let estimateSaveService: EstimateSaveServiceProtocol
    private let rooms: [RoomInput]
    private let editingEstimateID: UUID?

    init(
        rooms: [RoomInput],
        initialSelectedItems: [String: Double] = [:],
        editingEstimateID: UUID? = nil,
        catalogService: CatalogServiceProtocol? = nil,
        estimateSaveService: EstimateSaveServiceProtocol? = nil
    ) {
        self.rooms = rooms
        self._selectedItems = Published(initialValue: initialSelectedItems)
        self.editingEstimateID = editingEstimateID
        self.catalogService = catalogService ?? CatalogService()
        self.estimateSaveService = estimateSaveService ?? EstimateSaveService()
    }


    var currentSections: [WorkSection] {
        guard categories.indices.contains(selectedCategoryIndex) else { return [] }
        return categories[selectedCategoryIndex].sections
    }

    func load() {
        isLoading = true

        Task {
            defer { isLoading = false }

            do {
                let catalog = try await catalogService.loadCatalog()
                categories = catalog.categories
                if selectedCategoryIndex >= categories.count {
                    selectedCategoryIndex = 0
                }
            } catch {
                print("Load error: \(error)")
            }
        }
    }

    func showInfo(_ item: WorkItem) {
        infoItem = item
    }

    func showQuantity(_ item: WorkItem) {
        quantityItem = item
        isQuantitySheetPresented = true
    }

    func addItem(_ item: WorkItem, quantity: Double) {
        if quantity <= 0 {
            selectedItems[item.id] = nil
        } else {
            selectedItems[item.id] = quantity
        }
    }

    func removeItem(id: String) {
        selectedItems[id] = nil
    }

    func resetAll() {
        selectedItems.removeAll()
    }

    func totalSum() -> Double {
        categories
            .flatMap { $0.sections }
            .flatMap { $0.items }
            .reduce(0) { sum, item in
                sum + (selectedItems[item.id] ?? 0) * item.price
            }
    }

    func hasAnySelected() -> Bool {
        !selectedItems.isEmpty
    }

    func hasSelectedInCurrentCategory() -> Bool {
        guard categories.indices.contains(selectedCategoryIndex) else { return false }
        let ids = Set(categories[selectedCategoryIndex].sections.flatMap { $0.items.map { $0.id } })
        return selectedItems.keys.contains(where: { ids.contains($0) })
    }

    func isLastCategory() -> Bool {
        selectedCategoryIndex >= max(categories.count - 1, 0)
    }

    // Автоподстановка: если единица "кв.м"
    func suggestedQuantity(for item: WorkItem) -> Double? {
        let unit = item.unit.lowercased()
        if unit.contains("кв") || unit.contains("м2") {
            let total = rooms.reduce(0) { $0 + $1.area }
            return total > 0 ? total : nil
        }
        return nil
    }

    func saveEstimate() -> String {
        let lines = summaryLines()
        do {
            let estimate = try estimateSaveService.saveEstimate(
                id: editingEstimateID,
                total: totalSum(),
                rooms: rooms,
                selectedItems: selectedItems,
                lines: lines
            )

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ru_RU")
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return "Смета сохранена от \(formatter.string(from: estimate.createdAt))"
        } catch {
            return "Ошибка сохранения"
        }
    }

    func summaryLines() -> [EstimateSummaryLine] {
        categories
            .flatMap { $0.sections }
            .flatMap { $0.items }
            .compactMap { item in
                guard let q = selectedItems[item.id], q > 0 else { return nil }
                return EstimateSummaryLine(
                    itemId: item.id,
                    title: item.title,
                    quantity: q,
                    unit: item.unit,
                    unitPrice: item.price
                )
            }
    }
}
