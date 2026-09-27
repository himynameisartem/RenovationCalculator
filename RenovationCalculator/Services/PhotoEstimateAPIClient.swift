import Foundation

nonisolated struct PhotoEstimateResponse: Decodable, Sendable {
    let answer: String
    let sourcesCount: Int

    enum CodingKeys: String, CodingKey {
        case answer
        case sourcesCount = "sources_count"
    }
}

nonisolated enum PhotoEstimateAPIError: LocalizedError {
    case invalidServerURL
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidServerURL:
            return "Неверный адрес сервера расчёта."
        case .invalidResponse:
            return "Сервер расчёта вернул непонятный ответ."
        case .server(let message):
            return message
        }
    }
}

final class PhotoEstimateAPIClient: @unchecked Sendable {
    private let endpoint: URL
    private let session: URLSession

    init(baseURL: String, session: URLSession = .shared) throws {
        let normalized = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: normalized + "/estimate/from-cv") else {
            throw PhotoEstimateAPIError.invalidServerURL
        }
        endpoint = url
        self.session = session
    }

    func estimate(
        surfaces: RoomSurfaceAnalysis,
        roomType: String,
        roomName: String,
        area: Double,
        height: Double
    ) async throws -> PhotoEstimateResponse {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(RequestBody(
            roomType: roomType,
            roomName: roomName,
            areaM2: area,
            heightM: height,
            surfaces: surfaces
        ))

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw PhotoEstimateAPIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let detail = (try? JSONDecoder().decode(ErrorBody.self, from: data).detail)
            throw PhotoEstimateAPIError.server(
                detail ?? "Сервер расчёта вернул ошибку \(http.statusCode)."
            )
        }
        return try JSONDecoder().decode(PhotoEstimateResponse.self, from: data)
    }
}

nonisolated private struct RequestBody: Encodable {
    let roomType: String
    let roomName: String
    let areaM2: Double
    let heightM: Double
    let surfaces: RoomSurfaceAnalysis

    enum CodingKeys: String, CodingKey {
        case roomType = "room_type"
        case roomName = "room_name"
        case areaM2 = "area_m2"
        case heightM = "height_m"
        case surfaces
    }
}

nonisolated private struct ErrorBody: Decodable {
    let detail: String
}
