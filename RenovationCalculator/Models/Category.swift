//
//  CategoryModel.swift
//  RenovationCalculator
//
//  Created by Artem Kudryavtsev on 19.02.2026.
//

import Foundation

struct Category: Codable, Identifiable {
    let id: String
    let title: String
    let sections: [WorkSection]
}
