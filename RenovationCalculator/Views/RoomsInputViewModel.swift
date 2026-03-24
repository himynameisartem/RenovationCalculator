import Foundation
import Combine

final class RoomsInputViewModel: ObservableObject {
    @Published var rooms: [RoomInput] = []

    @Published var livingCount: Int = 0 { didSet { syncRooms(for: .living, count: livingCount) } }
    @Published var kitchenCount: Int = 0 { didSet { syncRooms(for: .kitchen, count: kitchenCount) } }
    @Published var bathroomCount: Int = 0 { didSet { syncRooms(for: .bathroom, count: bathroomCount) } }
    @Published var hallwayCount: Int = 0 { didSet { syncRooms(for: .hallway, count: hallwayCount) } }

    func roomsIndices(for type: RoomType) -> [Int] {
        rooms.indices.filter { rooms[$0].type == type }
    }

    func count(for type: RoomType) -> Int {
        rooms.filter { $0.type == type }.count
    }

    func totalArea() -> Double {
        rooms.reduce(0) { $0 + $1.area }
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
}

struct RoomInput: Identifiable, Equatable, Codable {
    let id: UUID
    let type: RoomType
    var index: Int
    var name: String
    var area: Double = 0
    var height: Double = 2.7
    var windows: Int = 0

    init(type: RoomType, index: Int) {
        self.id = UUID()
        self.type = type
        self.index = index
        self.name = index > 1 ? "\(type.title) \(index)" : type.title
    }
}

enum RoomType: String, CaseIterable, Identifiable, Codable {
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
