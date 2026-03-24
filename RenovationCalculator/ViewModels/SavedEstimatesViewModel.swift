import Foundation
import Combine

@MainActor
final class SavedEstimatesViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var estimates: [SavedEstimate] = []

    private let store: SavedEstimatesStore
    private let router: AppRouter
    private var cancellables = Set<AnyCancellable>()

    init(store: SavedEstimatesStore, router: AppRouter) {
        self.store = store
        self.router = router

        bindStore()
    }

    var hasEstimates: Bool {
        !estimates.isEmpty
    }

    func onAppear() {
        store.reload()
    }

    func showNewEstimate() {
        router.show(.rooms, resetViewTree: true)
    }

    func deleteEstimate(_ estimate: SavedEstimate) {
        store.delete(id: estimate.id)

        if !store.hasSavedEstimates {
            router.show(.rooms, resetViewTree: true)
        }
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func bindStore() {
        store.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)

        store.$estimates
            .receive(on: DispatchQueue.main)
            .assign(to: &$estimates)
    }
}
