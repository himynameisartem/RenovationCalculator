import Foundation

protocol CatalogServiceProtocol {
    func loadCatalog() async throws -> Catalog
}

final class CatalogService: CatalogServiceProtocol {
    private let loader: CatalogLoader

    init(loader: CatalogLoader = CatalogLoader()) {
        self.loader = loader
    }

    func loadCatalog() async throws -> Catalog {
        try await loader.loadRemoteCatalog()
    }
}
