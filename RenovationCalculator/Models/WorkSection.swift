//
//  WorkSectionModel.swift
//  RenovationCalculator
//
//  Created by Artem Kudryavtsev on 19.02.2026.
//

import Foundation

struct WorkSection: Codable, Identifiable {
    let id: String
    let title: String
    let items: [WorkItem]
}
