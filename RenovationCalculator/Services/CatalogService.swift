import Foundation

protocol CatalogServiceProtocol {
    func loadCatalog() async throws -> Catalog
}

final class CatalogService: CatalogServiceProtocol {
    private let loader: CatalogLoader
    private let fileManager: FileManager
    private let cacheFileName = "catalog-cache.json"

    init(
        loader: CatalogLoader = CatalogLoader(),
        fileManager: FileManager = .default
    ) {
        self.loader = loader
        self.fileManager = fileManager
    }

    func loadCatalog() async throws -> Catalog {
        do {
            let remoteData = try await loader.loadRemoteCatalogData()
            let catalog = try loader.decodeCatalog(from: remoteData)
            try saveCachedCatalogData(remoteData)
            return catalog
        } catch {
            let cachedData = try loadCachedCatalogData()
            return try loader.decodeCatalog(from: cachedData)
        }
    }

    private func saveCachedCatalogData(_ data: Data) throws {
        let url = try cacheFileURL()
        try data.write(to: url, options: .atomic)
    }

    private func loadCachedCatalogData() throws -> Data {
        let url = try cacheFileURL()
        return try Data(contentsOf: url)
    }

    private func cacheFileURL() throws -> URL {
        let directory = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let appDirectory = directory.appendingPathComponent("RenovationCalculator", isDirectory: true)
        if !fileManager.fileExists(atPath: appDirectory.path) {
            try fileManager.createDirectory(
                at: appDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        return appDirectory.appendingPathComponent(cacheFileName)
    }
}
