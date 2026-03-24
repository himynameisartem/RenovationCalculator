import Foundation

struct EstimateSummaryLine: Identifiable, Hashable {
    let id = UUID()
    let itemId: String
    let title: String
    let quantity: Double
    let unit: String
    let unitPrice: Double

    var subtotal: Double {
        quantity * unitPrice
    }
}
