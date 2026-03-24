import Foundation
import Combine

@MainActor
final class RoomsInputViewModel: ObservableObject {
    @Published var rooms: [RoomInput] = []
    @Published var goNext = false
    @Published private(set) var canOpenSavedEstimates = false

    @Published var livingCount: Int = 0 { didSet { syncRooms(for: .living, count: livingCount) } }
    @Published var kitchenCount: Int = 0 { didSet { syncRooms(for: .kitchen, count: kitchenCount) } }
    @Published var bathroomCount: Int = 0 { didSet { syncRooms(for: .bathroom, count: bathroomCount) } }
    @Published var hallwayCount: Int = 0 { didSet { syncRooms(for: .hallway, count: hallwayCount) } }

    private let store: SavedEstimatesStore
    private let router: AppRouter
    private var cancellables = Set<AnyCancellable>()

    init(store: SavedEstimatesStore, router: AppRouter) {
        self.store = store
        self.router = router
        self.canOpenSavedEstimates = store.hasSavedEstimates

        bindStore()
    }

    var isContinueButtonEnabled: Bool {
        livingCount > 0 ||
        kitchenCount > 0 ||
        bathroomCount > 0 ||
        hallwayCount > 0
    }

    func roomsIndices(for type: RoomType) -> [Int] {
        rooms.indices.filter { rooms[$0].type == type }
    }

    func count(for type: RoomType) -> Int {
        rooms.filter { $0.type == type }.count
    }

    func totalArea() -> Double {
        rooms.reduce(0) { $0 + $1.area }
    }

    func openSavedEstimates() {
        router.show(.savedEstimates, resetViewTree: true)
    }

    func skip() {
        goNext = true
    }

    func continueToEstimate() {
        goNext = true
    }

    private func syncRooms(for type: RoomType, count: Int) {
        let existing = roomsIndices(for: type)

        if existing.count < count {
            let toAdd = count - existing.count
            for i in 0..<toAdd {
                let index = existing.count + i + 1
                rooms.append(RoomInput(type: type, index: index))
            }
        } else if existing.count > count {
            let toRemove = existing.count - count
            let indicesToRemove = existing.suffix(toRemove).reversed()
            for idx in indicesToRemove {
                rooms.remove(at: idx)
            }
        }

        reindex(type: type)
    }

    private func reindex(type: RoomType) {
        var index = 1
        for i in rooms.indices where rooms[i].type == type {
            rooms[i].index = index
            if rooms[i].name.isEmpty || rooms[i].name.hasPrefix(type.title) {
                rooms[i].name = index > 1 ? "\(type.title) \(index)" : type.title
            }
            index += 1
        }
    }

    private func bindStore() {
        store.$estimates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] estimates in
                self?.canOpenSavedEstimates = !estimates.isEmpty
            }
            .store(in: &cancellables)
    }
}
