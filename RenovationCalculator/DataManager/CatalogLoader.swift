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
    private let remoteCatalogURLString = "https://sk-family.ru/db.json"
    private let decoder = JSONDecoder()

    func loadFromBundle() throws -> Catalog {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json") else {
            throw CatalogLoaderError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        return try decodeCatalog(from: data)
    }

    func loadRemoteCatalog() async throws -> Catalog {
        let data = try await loadRemoteCatalogData()
        return try decodeCatalog(from: data)
    }

    func loadRemoteCatalogData() async throws -> Data {
        guard let url = URL(string: remoteCatalogURLString) else {
            throw CatalogLoaderError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw CatalogLoaderError.invalidResponse
        }
        return data
    }

    func decodeCatalog(from data: Data) throws -> Catalog {
        try decoder.decode(Catalog.self, from: data)
    }
}
