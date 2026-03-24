import Foundation

struct SavedEstimateLine: Codable, Identifiable {
    let id: UUID
    let title: String
    let quantity: Double
    let unit: String
    let unitPrice: Double
    let subtotal: Double

    init(title: String, quantity: Double, unit: String, unitPrice: Double, subtotal: Double) {
        self.id = UUID()
        self.title = title
        self.quantity = quantity
        self.unit = unit
        self.unitPrice = unitPrice
        self.subtotal = subtotal
    }
}

struct SavedEstimate: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    let total: Double
    let lines: [SavedEstimateLine]

    init(total: Double, lines: [SavedEstimateLine]) {
        self.id = UUID()
        self.createdAt = Date()
        self.total = total
        self.lines = lines
    }
}

enum EstimateStorage {
    private static let folderName = "SavedEstimates"

    private static var directoryURL: URL {
        let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directory = baseURL.appendingPathComponent(folderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static func hasSavedEstimates() -> Bool {
        (try? loadAll().isEmpty) == false
    }

    static func save(total: Double, lines: [SavedEstimateLine]) throws -> SavedEstimate {
        let estimate = SavedEstimate(total: total, lines: lines)
        let data = try encoder.encode(estimate)
        let fileURL = directoryURL.appendingPathComponent("\(estimate.id.uuidString).json")
        try data.write(to: fileURL, options: .atomic)
        return estimate
    }

    static func loadAll() throws -> [SavedEstimate] {
        let urls = try FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        return try urls
            .filter { $0.pathExtension.lowercased() == "json" }
            .map { url in
                let data = try Data(contentsOf: url)
                return try decoder.decode(SavedEstimate.self, from: data)
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    static func delete(id: UUID) throws {
        let fileURL = directoryURL.appendingPathComponent("\(id.uuidString).json")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    static func deleteAll() throws {
        let urls = try FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        for url in urls where url.pathExtension.lowercased() == "json" {
            try FileManager.default.removeItem(at: url)
        }
    }
}
