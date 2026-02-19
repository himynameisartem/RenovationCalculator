//
//  CatalogLoader.swift
//  RenovationCalculator
//
//  Created by Artem Kudryavtsev on 19.02.2026.
//

import Foundation

enum CatalogLoaderError: Error {
    case fileNotFound
}


final class CatalogLoader {
    func loadFromBundle() throws -> Catalog {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json") else {
            throw CatalogLoaderError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Catalog.self, from: data)
    }
    
    func loadFromUrl(_ url: URL) throws -> Catalog {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Catalog.self, from: data)
    }
}
