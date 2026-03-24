import Foundation
import Combine

@MainActor
final class SavedEstimatesStore: ObservableObject {
    @Published var isLoading = false
    @Published private(set) var estimates: [SavedEstimate] = []

    init() {
        reload()
    }

    var hasSavedEstimates: Bool {
        !estimates.isEmpty
    }

    func reload() {
        isLoading = true
        estimates = (try? EstimateStorage.loadAll()) ?? []
        isLoading = false
    }

    func delete(id: UUID) {
        try? EstimateStorage.delete(id: id)
        reload()
    }
}
