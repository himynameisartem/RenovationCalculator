//
//  RoomInput.swift
//  RenovationCalculator
//
//  Created by Artem Kudryavtsev on 24.03.2026.
//

import Foundation

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
