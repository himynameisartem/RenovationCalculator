//
//  MainEstimateViewModel.swift
//  RenovationCalculator
//
//  Created by Artem Kudryavtsev on 19.02.2026.
//
import Foundation
import Combine

@MainActor
final class MainEstimateViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var selectedCategoryIndex: Int = 0
    @Published var infoItem: WorkItem?
    @Published var quantityItem: WorkItem?

    private let loader = CatalogLoader()

    var currentSections: [WorkSection] {
        guard categories.indices.contains(selectedCategoryIndex) else { return [] }
        return categories[selectedCategoryIndex].sections
    }

    func load() {
        do {
            let catalog = try loader.loadFromBundle()
            categories = catalog.categories
            if selectedCategoryIndex >= categories.count {
                selectedCategoryIndex = 0
            }
        } catch {
            print("Load error: \(error)")
        }
    }

    func showInfo(_ item: WorkItem) {
        infoItem = item
    }

    func showQuantity(_ item: WorkItem) {
        quantityItem = item
    }
}
