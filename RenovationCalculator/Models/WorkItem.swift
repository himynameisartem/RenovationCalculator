//
//  WorkItemModel.swift
//  RenovationCalculator
//
//  Created by Artem Kudryavtsev on 19.02.2026.
//

import Foundation

struct WorkItem: Codable, Identifiable {
    let id: String
    let title: String
    let unit: String
    let price: Double
    let description: String?
    let photos: [String]?
}
