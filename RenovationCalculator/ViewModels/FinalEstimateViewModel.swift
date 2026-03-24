import Foundation
import Combine

@MainActor
final class FinalEstimateViewModel: ObservableObject {
    @Published var showResetAlert = false
    @Published var showSaveAlert = false
    @Published var saveMessage = ""
    @Published private(set) var isSaved = false

    private let store: SavedEstimatesStore
    private let router: AppRouter
    private let onReset: () -> Void
    private let onSave: () -> String

    init(
        store: SavedEstimatesStore,
        router: AppRouter,
        onReset: @escaping () -> Void,
        onSave: @escaping () -> String
    ) {
        self.store = store
        self.router = router
        self.onReset = onReset
        self.onSave = onSave
    }

    var canOpenSavedEstimates: Bool {
        store.hasSavedEstimates || isSaved
    }

    func saveEstimate() {
        saveMessage = onSave()
        store.reload()
        isSaved = !saveMessage.lowercased().contains("ошибка")
        showSaveAlert = true
    }

    func openSavedEstimates() {
        store.reload()
        router.show(.savedEstimates, resetViewTree: true)
    }

    func startNewCalculation() {
        if isSaved {
            router.show(.rooms, resetViewTree: true)
        } else {
            showResetAlert = true
        }
    }

    func confirmResetAndStartNewCalculation() {
        onReset()
        router.show(.rooms, resetViewTree: true)
    }
}
