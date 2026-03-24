//
//  CatalogLoader.swift
//  RenovationCalculator
//
//  Created by Artem Kudryavtsev on 19.02.2026.
//

import Foundation

enum CatalogLoaderError: Error {
    case fileNotFound
    case invalidURL
    case invalidResponse
}


final class CatalogLoader {
    private let remoteCatalogURLString = "https://raw.githubusercontent.com/himynameisartem/my_test_json/refs/heads/main/db.json"

    func loadFromBundle() throws -> Catalog {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json") else {
            throw CatalogLoaderError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Catalog.self, from: data)
    }

    func loadRemoteCatalog() async throws -> Catalog {
        guard let url = URL(string: remoteCatalogURLString) else {
            throw CatalogLoaderError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw CatalogLoaderError.invalidResponse
        }
        return try JSONDecoder().decode(Catalog.self, from: data)
    }
}
