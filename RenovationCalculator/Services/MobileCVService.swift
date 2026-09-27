import CoreGraphics
import CoreML
import Foundation
import ImageIO
import Vision

nonisolated struct DetectedMaterial: Codable, Sendable, Equatable {
    let material: String
    let confidence: Double
}

nonisolated struct RoomSurfaceAnalysis: Codable, Sendable, Equatable {
    var walls: [DetectedMaterial]
    var floor: [DetectedMaterial]
    var ceiling: [DetectedMaterial]
    var visibleSurfaces: [String] = []

    enum CodingKeys: String, CodingKey {
        case walls
        case floor
        case ceiling
    }
}

nonisolated enum MobileCVError: LocalizedError {
    case modelNotFound(String)
    case invalidImage
    case invalidModelOutput(String)
    case noSurfaces
    case notRoom

    var errorDescription: String? {
        switch self {
        case .modelNotFound(let name):
            return "В приложении не найдена модель \(name)."
        case .invalidImage:
            return "Не удалось прочитать выбранное изображение."
        case .invalidModelOutput(let name):
            return "Модель \(name) вернула неожиданный результат."
        case .noSurfaces:
            return "На выбранных фото не найдены стены, пол или потолок."
        case .notRoom:
            return "На фотографии не видно помещения."
        }
    }
}

actor MobileCVService {
    static let shared = MobileCVService()

    private let segmentationSize = 512
    private let outputThreshold = 0.40
    private let roomStateThreshold = 0.60
    private let distinctCeilingThreshold = 0.75

    private let wallClasses = [
        "bare_unfinished_wall",
        "exposed_drywall",
        "rigid_decorative_cladding",
        "tile",
        "unfinished_plaster_or_putty",
        "wallpaper"
    ]
    private let floorClasses = [
        "bare_unfinished_floor",
        "carpet",
        "tile_or_stone",
        "vinyl_or_linoleum",
        "wood_flooring"
    ]
    private let ceilingClasses = [
        "bare_unfinished_ceiling",
        "drywall_ceiling",
        "glued_light_ceiling_finish",
        "modular_or_panel_ceiling",
        "stretch_ceiling"
    ]

    private lazy var segmentationModel = try! loadModel(named: "SurfaceSegmentation")
    private lazy var segmentationVisionModel = try! VNCoreMLModel(for: segmentationModel)
    private lazy var globalDINO = try! loadModel(named: "DINOv2Global")
    private lazy var localDINO = try! loadModel(named: "DINOv2Local")
    private lazy var wallHead = try! loadModel(named: "WallMaterialHead")
    private lazy var floorHead = try! loadModel(named: "FloorMaterialHead")
    private lazy var ceilingHead = try! loadModel(named: "CeilingMaterialHead")

    func analyze(imageData: [Data]) throws -> RoomSurfaceAnalysis {
        var scores: [SurfaceKind: [String: Double]] = [
            .walls: [:],
            .floor: [:],
            .ceiling: [:]
        ]
        var surfaceCoverage: [SurfaceKind: Double] = [
            .walls: 0,
            .floor: 0,
            .ceiling: 0
        ]
        var visibleSurfaceKinds = Set<SurfaceKind>()

        for data in imageData {
            guard let image = orientedCGImage(from: data) else {
                throw MobileCVError.invalidImage
            }
            let regions = try segment(image: image)
            for surface in [SurfaceKind.walls, .floor, .ceiling] {
                let surfaceRegions = regions[surface, default: []]
                let coveredPixels = surfaceRegions.reduce(0) { $0 + $1.area }
                let coverage = Double(coveredPixels) / Double(segmentationSize * segmentationSize)
                surfaceCoverage[surface] = max(surfaceCoverage[surface] ?? 0, coverage)
                if !surfaceRegions.isEmpty {
                    visibleSurfaceKinds.insert(surface)
                }
            }
            for (surface, surfaceRegions) in regions {
                for region in surfaceRegions {
                    let probabilities = try classify(region: region, surface: surface, image: image)
                    for (index, probability) in probabilities.enumerated()
                    where probability >= outputThreshold {
                        let material = classes(for: surface)[index]
                        scores[surface, default: [:]][material] = max(
                            scores[surface]?[material] ?? 0,
                            probability
                        )
                    }
                }
            }
        }

        let wallCoverage = surfaceCoverage[.walls] ?? 0
        let floorCoverage = surfaceCoverage[.floor] ?? 0
        let ceilingCoverage = surfaceCoverage[.ceiling] ?? 0
        let totalCoverage = wallCoverage + floorCoverage + ceilingCoverage
#if DEBUG
        print(
            "CV_MASKS walls=\(rounded(wallCoverage)) "
            + "floor=\(rounded(floorCoverage)) "
            + "ceiling=\(rounded(ceilingCoverage))"
        )
#endif
        guard visibleSurfaceKinds.count >= 2,
              visibleSurfaceKinds.contains(.walls),
              wallCoverage >= 0.12,
              totalCoverage >= 0.45 else {
            throw MobileCVError.notRoom
        }

        guard scores.values.contains(where: { !$0.isEmpty }) else {
            throw MobileCVError.noSurfaces
        }
        applyRoomConsistency(to: &scores)
#if DEBUG
        print("CV_RESULT walls: " + debugSummary(scores[.walls] ?? [:]))
        print("CV_RESULT floor: " + debugSummary(scores[.floor] ?? [:]))
        print("CV_RESULT ceiling: " + debugSummary(scores[.ceiling] ?? [:]))
#endif
        let visibleSurfaces = [
            (SurfaceKind.walls, "walls"),
            (SurfaceKind.floor, "floor"),
            (SurfaceKind.ceiling, "ceiling"),
        ]
        .filter { visibleSurfaceKinds.contains($0.0) }
        .map(\.1)
        return RoomSurfaceAnalysis(
            walls: sortedMaterials(scores[.walls] ?? [:]),
            floor: sortedMaterials(scores[.floor] ?? [:]),
            ceiling: sortedMaterials(scores[.ceiling] ?? [:]),
            visibleSurfaces: visibleSurfaces
        )
    }

    private func loadModel(named name: String) throws -> MLModel {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mlmodelc") else {
            throw MobileCVError.modelNotFound(name)
        }
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all
        return try MLModel(contentsOf: url, configuration: configuration)
    }

    private func orientedCGImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? NSNumber,
              let height = properties[kCGImagePropertyPixelHeight] as? NSNumber else {
            return nil
        }
        let maximumDimension = min(1024, max(width.intValue, height.intValue))
        let decodeOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumDimension,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        guard let oriented = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            decodeOptions as CFDictionary
        ) else {
            return nil
        }

        let normalizedData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            normalizedData,
            "public.jpeg" as CFString,
            1,
            nil
        ) else {
            return nil
        }
        CGImageDestinationAddImage(
            destination,
            oriented,
            [kCGImageDestinationLossyCompressionQuality: 0.95] as CFDictionary
        )
        guard CGImageDestinationFinalize(destination),
              let normalizedSource = CGImageSourceCreateWithData(
                normalizedData as CFData,
                nil
              ) else {
            return nil
        }
        let normalizedOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumDimension,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        return CGImageSourceCreateThumbnailAtIndex(
            normalizedSource,
            0,
            normalizedOptions as CFDictionary
        )
    }

    private func segment(image: CGImage) throws -> [SurfaceKind: [SurfaceRegion]] {
        let request = VNCoreMLRequest(model: segmentationVisionModel)
        request.imageCropAndScaleOption = .scaleFill
        let handler = VNImageRequestHandler(
            cgImage: image,
            orientation: .up,
            options: [:]
        )
        try handler.perform([request])
        guard let observations = request.results as? [VNCoreMLFeatureValueObservation],
              let values = observations.first(where: {
                $0.featureName == "surface_masks"
              })?.featureValue.multiArrayValue,
              values.shape.count == 4 else {
            throw MobileCVError.invalidModelOutput("SurfaceSegmentation")
        }

        let thresholds = [0.50, 0.40, 0.40, 0.40]
        var components: [[Component]] = []
        for channel in 0..<4 {
            var mask = [UInt8](repeating: 0, count: segmentationSize * segmentationSize)
            for y in 0..<segmentationSize {
                for x in 0..<segmentationSize {
                    if multiArrayValue(values, [0, channel, y, x]) >= thresholds[channel] {
                        mask[y * segmentationSize + x] = 1
                    }
                }
            }
            let cleaned = eroded(mask: mask, width: segmentationSize, height: segmentationSize)
            let minimumFraction = [0.03, 0.02, 0.02, 0.01][channel]
            components.append(connectedComponents(
                mask: cleaned,
                width: segmentationSize,
                height: segmentationSize,
                minimumFraction: minimumFraction
            ))
        }

        let floorComponents = components[1]
        let minimumArea = Int(Double(segmentationSize * segmentationSize) * 0.02)
        let visibleFloor = floorComponents.first.map { $0.area >= minimumArea } ?? false

        return [
            .walls: Array(components[0].prefix(3)).map(SurfaceRegion.init),
            .floor: Array((visibleFloor ? components[1] : components[2]).prefix(3)).map(SurfaceRegion.init),
            .ceiling: Array(components[3].prefix(3)).map(SurfaceRegion.init)
        ]
    }

    private func classify(
        region: SurfaceRegion,
        surface: SurfaceKind,
        image: CGImage
    ) throws -> [Double] {
        let globalBuffer = try maskedPixelBuffer(
            image: image,
            region: region,
            outputSize: 448
        )
        let globalEmbedding = try embedding(
            model: globalDINO,
            pixelBuffer: globalBuffer,
            modelName: "DINOv2Global"
        )

        let boxes = localBoxes(for: region)
        var localValues = [Double]()
        localValues.reserveCapacity(9 * 384)
        for box in boxes {
            let crop = imageCropBox(segmentationBox: box, image: image)
            guard let cropped = image.cropping(to: crop) else {
                throw MobileCVError.invalidImage
            }
            let buffer = try pixelBuffer(from: cropped, width: 224, height: 224)
            localValues.append(contentsOf: try embedding(
                model: localDINO,
                pixelBuffer: buffer,
                modelName: "DINOv2Local"
            ))
        }

        let globalArray = try MLMultiArray(shape: [1, 384], dataType: .float32)
        for index in 0..<384 {
            globalArray[index] = NSNumber(value: Float(globalEmbedding[index]))
        }
        let localArray = try MLMultiArray(shape: [1, 9, 384], dataType: .float32)
        for index in 0..<(9 * 384) {
            localArray[index] = NSNumber(value: Float(localValues[index]))
        }

        let model: MLModel
        let modelName: String
        switch surface {
        case .walls:
            model = wallHead
            modelName = "WallMaterialHead"
        case .floor:
            model = floorHead
            modelName = "FloorMaterialHead"
        case .ceiling:
            model = ceilingHead
            modelName = "CeilingMaterialHead"
        }
        let output = try model.prediction(
            from: MLDictionaryFeatureProvider(dictionary: [
                "global_embedding": MLFeatureValue(multiArray: globalArray),
                "local_embeddings": MLFeatureValue(multiArray: localArray)
            ])
        )
        guard let probabilities = output.featureValue(for: "probabilities")?.multiArrayValue else {
            throw MobileCVError.invalidModelOutput(modelName)
        }
        return (0..<classes(for: surface).count).map {
            multiArrayValue(probabilities, [0, $0])
        }
    }

    private func embedding(
        model: MLModel,
        pixelBuffer: CVPixelBuffer,
        modelName: String
    ) throws -> [Double] {
        let output = try model.prediction(
            from: MLDictionaryFeatureProvider(dictionary: [
                "image": MLFeatureValue(pixelBuffer: pixelBuffer)
            ])
        )
        guard let array = output.featureValue(for: "embedding")?.multiArrayValue else {
            throw MobileCVError.invalidModelOutput(modelName)
        }
        return (0..<384).map { multiArrayValue(array, [0, $0]) }
    }

    private func multiArrayValue(_ array: MLMultiArray, _ indices: [Int]) -> Double {
        let offset = zip(indices, array.strides).reduce(0) {
            $0 + $1.0 * $1.1.intValue
        }
        return array[offset].doubleValue
    }

    private func classes(for surface: SurfaceKind) -> [String] {
        switch surface {
        case .walls: return wallClasses
        case .floor: return floorClasses
        case .ceiling: return ceilingClasses
        }
    }

    private func sortedMaterials(_ scores: [String: Double]) -> [DetectedMaterial] {
        scores
            .map { DetectedMaterial(material: $0.key, confidence: rounded($0.value)) }
            .sorted { $0.confidence > $1.confidence }
    }

    private func applyRoomConsistency(to scores: inout [SurfaceKind: [String: Double]]) {
        let walls = scores[.walls] ?? [:]
        let floor = scores[.floor] ?? [:]
        let ceiling = scores[.ceiling] ?? [:]
        let bareWall = walls["bare_unfinished_wall"] ?? 0
        let bareFloor = floor["bare_unfinished_floor"] ?? 0
        let strongestFinishedWall = walls
            .filter { $0.key != "bare_unfinished_wall" }
            .map(\.value)
            .max() ?? 0
        let unfinishedRoom = bareWall >= roomStateThreshold
            && bareFloor >= roomStateThreshold
            && bareWall >= strongestFinishedWall
        let distinctiveCeiling = max(
            ceiling["stretch_ceiling"] ?? 0,
            ceiling["glued_light_ceiling_finish"] ?? 0,
            ceiling["modular_or_panel_ceiling"] ?? 0
        )
        if unfinishedRoom && distinctiveCeiling < distinctCeilingThreshold {
            scores[.ceiling] = ["bare_unfinished_ceiling": min(bareWall, bareFloor)]
        }
    }

    private func debugSummary(_ scores: [String: Double]) -> String {
        guard !scores.isEmpty else { return "not found" }
        return scores
            .sorted { $0.value > $1.value }
            .map { "\($0.key)=\(rounded($0.value))" }
            .joined(separator: ", ")
    }

    private func rounded(_ value: Double) -> Double {
        (value * 1000).rounded() / 1000
    }

    private func eroded(mask: [UInt8], width: Int, height: Int) -> [UInt8] {
        var integral = [Int](repeating: 0, count: (width + 1) * (height + 1))
        for y in 0..<height {
            var rowSum = 0
            for x in 0..<width {
                rowSum += Int(mask[y * width + x])
                integral[(y + 1) * (width + 1) + x + 1] = integral[y * (width + 1) + x + 1] + rowSum
            }
        }
        var result = [UInt8](repeating: 0, count: mask.count)
        guard width >= 5, height >= 5 else { return result }
        for y in 2..<(height - 2) {
            for x in 2..<(width - 2) {
                let x0 = x - 2, y0 = y - 2, x1 = x + 3, y1 = y + 3
                let sum = integral[y1 * (width + 1) + x1]
                    - integral[y0 * (width + 1) + x1]
                    - integral[y1 * (width + 1) + x0]
                    + integral[y0 * (width + 1) + x0]
                if sum == 25 { result[y * width + x] = 1 }
            }
        }
        return result
    }

    private func connectedComponents(
        mask: [UInt8],
        width: Int,
        height: Int,
        minimumFraction: Double
    ) -> [Component] {
        var visited = [UInt8](repeating: 0, count: mask.count)
        var result: [Component] = []
        let minimumArea = Int(Double(width * height) * minimumFraction)

        for start in 0..<mask.count where mask[start] == 1 && visited[start] == 0 {
            var stack = [start]
            visited[start] = 1
            var pixels: [Int] = []
            var minX = width, minY = height, maxX = 0, maxY = 0
            while let index = stack.popLast() {
                pixels.append(index)
                let x = index % width
                let y = index / width
                minX = min(minX, x); maxX = max(maxX, x)
                minY = min(minY, y); maxY = max(maxY, y)
                if x > 0 { appendNeighbor(index - 1, mask: mask, visited: &visited, stack: &stack) }
                if x + 1 < width { appendNeighbor(index + 1, mask: mask, visited: &visited, stack: &stack) }
                if y > 0 { appendNeighbor(index - width, mask: mask, visited: &visited, stack: &stack) }
                if y + 1 < height { appendNeighbor(index + width, mask: mask, visited: &visited, stack: &stack) }
            }
            let boxWidth = maxX - minX + 1
            let boxHeight = maxY - minY + 1
            guard pixels.count >= minimumArea, boxWidth >= 32, boxHeight >= 32 else { continue }
            var localMask = [UInt8](repeating: 0, count: boxWidth * boxHeight)
            for index in pixels {
                let x = index % width - minX
                let y = index / width - minY
                localMask[y * boxWidth + x] = 1
            }
            result.append(Component(
                x0: minX,
                y0: minY,
                x1: maxX + 1,
                y1: maxY + 1,
                mask: localMask,
                area: pixels.count
            ))
        }
        return result.sorted { $0.area > $1.area }
    }

    private func appendNeighbor(
        _ index: Int,
        mask: [UInt8],
        visited: inout [UInt8],
        stack: inout [Int]
    ) {
        if mask[index] == 1 && visited[index] == 0 {
            visited[index] = 1
            stack.append(index)
        }
    }

    private func localBoxes(for region: SurfaceRegion) -> [IntBox] {
        let width = region.width
        let height = region.height
        let boxSize = min(max(24, Int(Double(min(width, height)) * 0.30)), width, height)
        let integral = integralMask(region.mask, width: width, height: height)
        let step = max(6, boxSize / 4)
        var xs = Array(Swift.stride(from: 0, through: max(0, width - boxSize), by: step))
        var ys = Array(Swift.stride(from: 0, through: max(0, height - boxSize), by: step))
        if xs.last != width - boxSize { xs.append(width - boxSize) }
        if ys.last != height - boxSize { ys.append(height - boxSize) }

        var candidates: [LocalCandidate] = []
        for y in ys {
            for x in xs {
                let covered = integralCoverage(
                    integral,
                    width: width,
                    x0: x,
                    y0: y,
                    x1: x + boxSize,
                    y1: y + boxSize
                )
                if covered >= 0.72 {
                    candidates.append(LocalCandidate(
                        box: IntBox(x0: x, y0: y, x1: x + boxSize, y1: y + boxSize),
                        coverage: covered,
                        centerX: (Double(x) + Double(boxSize) / 2) / Double(width),
                        centerY: (Double(y) + Double(boxSize) / 2) / Double(height)
                    ))
                }
            }
        }
        if candidates.isEmpty {
            candidates = [LocalCandidate(
                box: IntBox(
                    x0: (width - boxSize) / 2,
                    y0: (height - boxSize) / 2,
                    x1: (width + boxSize) / 2,
                    y1: (height + boxSize) / 2
                ),
                coverage: 0,
                centerX: 0.5,
                centerY: 0.5
            )]
        }

        var selected: [IntBox] = []
        var used = Set<Int>()
        for targetY in [0.17, 0.50, 0.83] {
            for targetX in [0.17, 0.50, 0.83] {
                let ranked = candidates.indices.sorted {
                    candidateDistance(candidates[$0], x: targetX, y: targetY)
                        < candidateDistance(candidates[$1], x: targetX, y: targetY)
                }
                let chosen = ranked.first(where: { !used.contains($0) }) ?? ranked[0]
                used.insert(chosen)
                let box = candidates[chosen].box
                selected.append(IntBox(
                    x0: region.x0 + box.x0,
                    y0: region.y0 + box.y0,
                    x1: region.x0 + box.x1,
                    y1: region.y0 + box.y1
                ))
            }
        }
        return selected
    }

    private func candidateDistance(_ candidate: LocalCandidate, x: Double, y: Double) -> Double {
        pow(candidate.centerX - x, 2) + pow(candidate.centerY - y, 2) - 0.20 * candidate.coverage
    }

    private func integralMask(_ mask: [UInt8], width: Int, height: Int) -> [Int] {
        var result = [Int](repeating: 0, count: (width + 1) * (height + 1))
        for y in 0..<height {
            var row = 0
            for x in 0..<width {
                row += Int(mask[y * width + x])
                result[(y + 1) * (width + 1) + x + 1] = result[y * (width + 1) + x + 1] + row
            }
        }
        return result
    }

    private func integralCoverage(
        _ integral: [Int],
        width: Int,
        x0: Int,
        y0: Int,
        x1: Int,
        y1: Int
    ) -> Double {
        let rowWidth = width + 1
        let sum = integral[y1 * rowWidth + x1]
            - integral[y0 * rowWidth + x1]
            - integral[y1 * rowWidth + x0]
            + integral[y0 * rowWidth + x0]
        return Double(sum) / Double((x1 - x0) * (y1 - y0))
    }

    private func imageCropBox(segmentationBox box: IntBox, image: CGImage) -> CGRect {
        let scaleX = Double(image.width) / Double(segmentationSize)
        let scaleY = Double(image.height) / Double(segmentationSize)
        let x0 = max(0, Int((Double(box.x0) * scaleX).rounded(.down)))
        let y0 = max(0, Int((Double(box.y0) * scaleY).rounded(.down)))
        let x1 = min(image.width, Int((Double(box.x1) * scaleX).rounded(.up)))
        let y1 = min(image.height, Int((Double(box.y1) * scaleY).rounded(.up)))
        return CGRect(x: x0, y: y0, width: max(1, x1 - x0), height: max(1, y1 - y0))
    }

    private func maskedPixelBuffer(
        image: CGImage,
        region: SurfaceRegion,
        outputSize: Int
    ) throws -> CVPixelBuffer {
        let cropBox = imageCropBox(segmentationBox: region.box, image: image)
        guard let crop = image.cropping(to: cropBox) else { throw MobileCVError.invalidImage }
        let buffer = try pixelBuffer(from: crop, width: outputSize, height: outputSize)
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let base = CVPixelBufferGetBaseAddress(buffer) else { throw MobileCVError.invalidImage }
        let rowBytes = CVPixelBufferGetBytesPerRow(buffer)
        let bytes = base.assumingMemoryBound(to: UInt8.self)
        for y in 0..<outputSize {
            let maskY = min(region.height - 1, y * region.height / outputSize)
            for x in 0..<outputSize {
                let maskX = min(region.width - 1, x * region.width / outputSize)
                if region.mask[maskY * region.width + maskX] == 0 {
                    let offset = y * rowBytes + x * 4
                    bytes[offset] = 128
                    bytes[offset + 1] = 128
                    bytes[offset + 2] = 128
                    bytes[offset + 3] = 255
                }
            }
        }
        return buffer
    }

    private func pixelBuffer(from image: CGImage, width: Int, height: Int) throws -> CVPixelBuffer {
        var buffer: CVPixelBuffer?
        let attributes: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &buffer
        )
        guard status == kCVReturnSuccess, let buffer else { throw MobileCVError.invalidImage }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let base = CVPixelBufferGetBaseAddress(buffer),
              let context = CGContext(
                data: base,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                    | CGBitmapInfo.byteOrder32Little.rawValue
              ) else {
            throw MobileCVError.invalidImage
        }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return buffer
    }
}

nonisolated private enum SurfaceKind: Hashable, Sendable {
    case walls
    case floor
    case ceiling
}

nonisolated private struct IntBox: Sendable {
    let x0: Int
    let y0: Int
    let x1: Int
    let y1: Int
}

nonisolated private struct Component: Sendable {
    let x0: Int
    let y0: Int
    let x1: Int
    let y1: Int
    let mask: [UInt8]
    let area: Int
}

nonisolated private struct SurfaceRegion: Sendable {
    let x0: Int
    let y0: Int
    let x1: Int
    let y1: Int
    let mask: [UInt8]

    init(_ component: Component) {
        x0 = component.x0
        y0 = component.y0
        x1 = component.x1
        y1 = component.y1
        mask = component.mask
    }

    var width: Int { x1 - x0 }
    var height: Int { y1 - y0 }
    var area: Int { mask.reduce(0) { $0 + Int($1) } }
    var box: IntBox { IntBox(x0: x0, y0: y0, x1: x1, y1: y1) }
}

nonisolated private struct LocalCandidate {
    let box: IntBox
    let coverage: Double
    let centerX: Double
    let centerY: Double
}
