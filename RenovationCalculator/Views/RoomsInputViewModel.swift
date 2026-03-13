import Foundation
import Combine

final class RoomsInputViewModel: ObservableObject {
    @Published var livingCount: Int = 0 { didSet { syncRooms(for: .living, count: livingCount) } }
    @Published var kitchenCount: Int = 0 { didSet { syncRooms(for: .kitchen, count: kitchenCount) } }
    @Published var bathroomCount: Int = 0 { didSet { syncRooms(for: .bathroom, count: bathroomCount) } }
    @Published var hallwayCount: Int = 0 { didSet { syncRooms(for: .hallway, count: hallwayCount) } }

    @Published private(set) var rooms: [RoomInput] = []

    func rooms(for type: RoomType) -> [RoomInput] {
        rooms.filter { $0.type == type }
    }

    func count(for type: RoomType) -> Int {
        rooms.filter { $0.type == type }.count
    }

    func totalArea() -> Double {
        rooms.reduce(0) { $0 + $1.area }
    }

    func syncRooms(for type: RoomType, count: Int) {
        let existing = rooms.filter { $0.type == type }
        if existing.count < count {
            let toAdd = count - existing.count
            for i in 0..<toAdd {
                let index = existing.count + i + 1
                rooms.append(RoomInput(type: type, index: index))
            }
        } else if existing.count > count {
            let toRemove = existing.count - count
            var removed = 0
            rooms.removeAll { r in
                if r.type == type && removed < toRemove {
                    removed += 1
                    return true
                }
                return false
            }
        }
        reindex(type: type)
    }

    func updateRoom(_ updated: RoomInput) {
        if let idx = rooms.firstIndex(where: { $0.id == updated.id }) {
            rooms[idx] = updated
        }
    }

    private func reindex(type: RoomType) {
        var index = 1
        for i in rooms.indices where rooms[i].type == type {
            rooms[i].index = index
            index += 1
        }
    }
}

struct RoomInput: Identifiable, Equatable {
    let id = UUID()
    let type: RoomType
    var index: Int
    var name: String
    var area: Double = 0
    var height: Double = 2.7
    var windows: Int = 0

    init(type: RoomType, index: Int) {
        self.type = type
        self.index = index
        self.name = index > 1 ? "\(type.title) \(index)" : type.title
    }
}

enum RoomType: String, CaseIterable, Identifiable {
    case living
    case kitchen
    case bathroom
    case hallway

    var id: String { rawValue }

    var title: String {
        switch self {
        case .living: return "Жилая"
        case .kitchen: return "Кухня"
        case .bathroom: return "Санузел"
        case .hallway: return "Прихожая"
        }
    }
}
//