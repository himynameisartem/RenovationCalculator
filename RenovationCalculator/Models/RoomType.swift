//
//  RoomType.swift
//  RenovationCalculator
//
//  Created by Artem Kudryavtsev on 24.03.2026.
//

import Foundation

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
