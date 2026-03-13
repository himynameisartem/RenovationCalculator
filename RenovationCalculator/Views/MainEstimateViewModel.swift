import Foundation
import Combine

@MainActor
final class MainEstimateViewModel: ObservableObject {
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

    private let loader = CatalogLoader()
    private let rooms: [RoomInput]

    init(rooms: [RoomInput]) {
        self.rooms = rooms
    }


    var currentSections: [WorkSection] {
        guard categories.indices.contains(selectedCategoryIndex) else { return [] }
        return categories[selectedCategoryIndex].sections
    }

    func load() {
        do {
            let catalog = try loader.loadFromBundle()
            categories = catalog.categories
            if selectedCategoryIndex >= categories.count {
                selectedCategoryIndex = 0
            }
        } catch {
            print("Load error: \(error)")
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

    func saveEstimate() -> String? {
        let lines = summaryLines()
        let payload = EstimateExport(
            createdAt: ISO8601DateFormatter().string(from: Date()),
            total: totalSum(),
            lines: lines.map {
                EstimateExport.Line(
                    title: $0.title,
                    quantity: $0.quantity,
                    unit: $0.unit,
                    unitPrice: $0.unitPrice,
                    subtotal: $0.subtotal
                )
            }
        )
        do {
            let data = try JSONEncoder().encode(payload)
            let fileName = "estimate-\(Int(Date().timeIntervalSince1970)).json"
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(fileName)
            try data.write(to: url)
            return "Смета сохранена: \(fileName)"
        } catch {
            return "Ошибка сохранения"
        }
    }

    struct SummaryLine: Identifiable {
        let id = UUID()
        let itemId: String
        let title: String
        let quantity: Double
        let unit: String
        let unitPrice: Double
        var subtotal: Double { quantity * unitPrice }
    }

    func summaryLines() -> [SummaryLine] {
        categories
            .flatMap { $0.sections }
            .flatMap { $0.items }
            .compactMap { item in
                guard let q = selectedItems[item.id], q > 0 else { return nil }
                return SummaryLine(
                    itemId: item.id,
                    title: item.title,
                    quantity: q,
                    unit: item.unit,
                    unitPrice: item.price
                )
            }
    }
}

struct EstimateExport: Codable {
    let createdAt: String
    let total: Double
    let lines: [Line]

    struct Line: Codable {
        let title: String
        let quantity: Double
        let unit: String
        let unitPrice: Double
        let subtotal: Double
    }
}
