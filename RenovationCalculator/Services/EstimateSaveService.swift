import Foundation

protocol EstimateSaveServiceProtocol {
    func saveEstimate(
        id: UUID?,
        total: Double,
        rooms: [RoomInput],
        selectedItems: [String: Double],
        lines: [EstimateSummaryLine]
    ) throws -> SavedEstimate
}

final class EstimateSaveService: EstimateSaveServiceProtocol {
    func saveEstimate(
        id: UUID?,
        total: Double,
        rooms: [RoomInput],
        selectedItems: [String: Double],
        lines: [EstimateSummaryLine]
    ) throws -> SavedEstimate {
        let savedLines = lines.map {
            SavedEstimateLine(
                title: $0.title,
                quantity: $0.quantity,
                unit: $0.unit,
                unitPrice: $0.unitPrice,
                subtotal: $0.subtotal
            )
        }

        return try EstimateStorage.save(
            id: id,
            total: total,
            rooms: rooms,
            selectedItems: selectedItems,
            lines: savedLines
        )
    }
}
