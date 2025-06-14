// There are a lot of issues with this.
// First of all, it's very inaccurate.
// Second, it's not power efficient.

import Foundation
import CoreML
import UIKit
import Accelerate
import Metal

class BeaconObstacleDetector: ObservableObject {
    // MARK: - Configuration
    
    /// Class IDs to ignore outright (including “Path” as one entry).
    private let ignoredClassIDs: Set<Int32> = [52, 2, 3, 6, 11, 13]
    
    /// Disparity threshold fraction (relative to the frame’s global max).
    private let thresholdDisparity: Float = 0.6
    
    /// Input size for TopFormer (semantic segmentation): 512×512.
    private let segWidth: Int = 512
    private let segHeight: Int = 512
    private let segPixels: Int = 512 * 512
    private let classes: Int = 150
    
    /// Input size for MiDaS (disparity): 256×256.
    private let depthWidth: Int = 256
    private let depthHeight: Int = 256
    private let depthPixels: Int = 256 * 256
    
    
    // MARK: - Models
    
    private let topFormer: TopFormer = {
        do {
            let config = MLModelConfiguration()
            return try TopFormer(configuration: config)
        } catch {
            fatalError("Failed to load TopFormer model: \(error)")
        }
    }()
    
    private let miDaS: MiDaS = {
        do {
            let config = MLModelConfiguration()
            return try MiDaS(configuration: config)
        } catch {
            fatalError("Failed to load MiDaS model: \(error)")
        }
    }()
    
    // MARK: - UI Update
    @Published var message: String = "Waiting for result."
    
    /// Main entry: run segmentation + disparity + obstacle masking
    func detect(_ inputImage: CGImage, frame: Int) {
        DispatchQueue.global(qos: .userInitiated).async {
            let obstacles = self.detectObstacles(from: inputImage)
            guard let obstacles = obstacles else {
                return
            }
            let message = self.describeObstacleImage(zonePercentages: obstacles.1, zoneClasses: obstacles.2) ?? "Continue ahead."
            DispatchQueue.main.async {
                self.message = message
            }
        }
    }
    
    
    // MARK: - Main Algorithm
    
    
    /// Perform obstacle detection from a CGImage.
    /// The zones are top left, top mid, top right, bottom left, bottom mid, and bottom right.
    /// - Parameter from: The input CGImage to process.
    /// - Returns: A tuple containing a boolean array, indicating:
    ///                          (i) whether each pixel is an obstacle,
    ///                          (ii) the obstacle percentage per zone,
    ///                          (iii) the most frequent obstacle class ID per zone.
    private func detectObstacles(from image: CGImage) -> ([Bool], [Float], [Int])? {
        // 1. Create pixel buffers for CoreML inputs
        guard
            let segBuffer = pixelBuffer(from: image, width: segWidth, height: segHeight),
            let depthBuffer = pixelBuffer(from: image, width: depthWidth, height: depthHeight)
        else {
            return nil
        }
        
        // 2. Run TopFormer (segmentation)
        guard let segOutput = try? topFormer.prediction(input_image: segBuffer) else {
            return nil
        }
        let channelCount = Int32(classes)
        let pixelCount = Int32(segPixels)
        var segmentation = [Int32](repeating: 0, count: segPixels)
        segOutput.var_1347.withUnsafeBufferPointer(ofType: Float.self) { semPtr in
            segmentation.withUnsafeMutableBufferPointer { outPtr in
                computeArgmax(
                    semPtr.baseAddress,
                    channelCount,
                    pixelCount,
                    outPtr.baseAddress
                )
            }
        }
        
        var finalLabels = [Int32](repeating: 0, count: segPixels)

        // 2.1 Calculate connected components
        segmentation.withUnsafeBufferPointer { segPtr in
            finalLabels.withUnsafeMutableBufferPointer { outPtr in
                findConnectedComponents(
                    segPtr.baseAddress,
                    Int32(segWidth),
                    Int32(segHeight),
                    outPtr.baseAddress
                )
            }
        }
        
        // 3. Run MiDaS (disparity)
        guard let depthOutput = try? miDaS.prediction(x_1: depthBuffer) else {
            return nil
        }
        let dispArray = depthOutput.var_1438  // [1,256,256]
        
        
        // 3.1 Upsample disparity from 256×256 to 512×512 using vImage
        // Extract and use raw 256×256 float buffer via withUnsafeMutableBytes
        var dispUpsampled = [Float](repeating: 0, count: segPixels)
        dispArray.withUnsafeMutableBytes { rawBuffer, _ in
            let dispPtr = rawBuffer.bindMemory(to: Float.self).baseAddress!
            var srcBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: dispPtr),
                                          height: vImagePixelCount(depthHeight),
                                          width: vImagePixelCount(depthWidth),
                                          rowBytes: depthWidth * MemoryLayout<Float>.stride)
            // Use withUnsafeMutableBufferPointer for destination
            dispUpsampled.withUnsafeMutableBufferPointer { destPtr in
                var dstBuffer = vImage_Buffer(data: destPtr.baseAddress!,
                                              height: vImagePixelCount(segHeight),
                                              width: vImagePixelCount(segWidth),
                                              rowBytes: segWidth * MemoryLayout<Float>.stride)
                vImageScale_PlanarF(&srcBuffer, &dstBuffer, nil, vImage_Flags(kvImageHighQualityResampling))
            }
        }
    
        
        // 4. Determine the connected components that are obstacles
        var maxDisp = [Float](repeating: -Float.greatestFiniteMagnitude, count: segPixels)
        var classLabel = [Int32](repeating: -1, count: segPixels)
        let globalMaxDisp = dispUpsampled.max() ?? 0
        let threshold = thresholdDisparity * globalMaxDisp
        
        for i in 0..<segPixels {
            let root = Int(finalLabels[i])
            let label = segmentation[i]
            let d = dispUpsampled[i]
            if classLabel[root] == -1 {
                classLabel[root] = label
            }
            if d > maxDisp[root] {
                maxDisp[root] = d
            }
        }
        
        // Prepare per-zone, per-class counts
        var zoneClassCounts = [Int](repeating: 0, count: 6 * classes)
        
        var valid = [Bool](repeating: false, count: segPixels) // If true, this pixel is obstacle
        var zoneTotals = [Int](repeating: 0, count: 6)
        for i in 0..<segPixels {
            let root = Int(finalLabels[i])
            if !ignoredClassIDs.contains(classLabel[root]) && maxDisp[root] < threshold {
                valid[i] = true

                // Determine which zone this pixel belongs to and add to the zone totals
                let x = i % segWidth
                let y = i / segWidth
                let topZoneHeight = Int(Float(segHeight) * 0.3)
                let bottomZoneStart = segHeight - Int(Float(segHeight) * 0.4)
                let leftWidth = Int(Float(segWidth) * 0.25)
                let midEnd = segWidth - leftWidth
                var zone = -1
                if y < topZoneHeight {
                    if x < leftWidth {
                        zone = 0
                    } else if x < midEnd {
                        zone = 1
                    } else {
                        zone = 2
                    }
                } else if y >= bottomZoneStart {
                    if x < leftWidth {
                        zone = 3
                    } else if x < midEnd {
                        zone = 4
                    } else {
                        zone = 5
                    }
                }
                if zone >= 0 {
                    zoneTotals[zone] += 1
                    let classID = Int(segmentation[i])
                    zoneClassCounts[zone * classes + classID] += 1
                }
            }
        }
        
        // 4.1 Compute obstacle percentage per zone
        let topZoneHeight = Int(Float(segHeight) * 0.3)
        let bottomZoneStart = segHeight - Int(Float(segHeight) * 0.4)
        let leftWidth = Int(Float(segWidth) * 0.25)
        let midWidth = segWidth - 2 * leftWidth
        let bottomZoneHeight = segHeight - bottomZoneStart

        let zonePixelCounts: [Int] = [
            topZoneHeight * leftWidth,
            topZoneHeight * midWidth,
            topZoneHeight * leftWidth,
            bottomZoneHeight * leftWidth,
            bottomZoneHeight * midWidth,
            bottomZoneHeight * leftWidth
        ]

        var zones = [Float](repeating: 0, count: 6)
        for j in 0..<6 {
            zones[j] = Float(zoneTotals[j]) / Float(zonePixelCounts[j])
        }

        // 4.2 Determine most frequent class ID per zone
        var zoneMaxClassIDs = [Int](repeating: 0, count: 6)
        for j in 0..<6 {
            let offset = j * classes
            let slice = zoneClassCounts[offset..<offset + classes]
            if let (maxIndex, _) = slice.enumerated().max(by: { $0.element < $1.element }) {
                zoneMaxClassIDs[j] = maxIndex
            }
        }

        return (valid, zones, zoneMaxClassIDs)
    }
    
    private func createObstacleImage(from valid: [Bool]) -> CGImage? {
        let maskBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: segPixels)
        for i in 0..<segPixels {
            maskBytes[i] = valid[i] ? 255 : 0 // If white, this pixel is obstacle
        }
        let grayColorSpace = CGColorSpaceCreateDeviceGray()
        let context = CGContext(data: maskBytes,
                                width: segWidth,
                                height: segHeight,
                                bitsPerComponent: 8,
                                bytesPerRow: segWidth,
                                space: grayColorSpace,
                                bitmapInfo: CGImageAlphaInfo.none.rawValue)
        guard let maskCGImage = context?.makeImage() else {
            maskBytes.deallocate()
            return nil
        }
        maskBytes.deallocate()
        return maskCGImage
    }
    
    private func describeObstacleImage(zonePercentages: [Float], zoneClasses: [Int]) -> String? {
        // We define a zone to have an obstacle if the percentage of obstacles is above 0.3.
        var zones = [Bool](repeating: false, count: 6)
        for i in 0..<6 {
            if zonePercentages[i] > 0.3 {
                zones[i] = true
            }
        }
        
        // 1. If both top mid and bottom mid zones have no obstacles, move ahead.
        if !zones[1] && !zones[4] {
            return nil
        }
        
        var obstacleName = zones[1] ? BeaconObstacleDetector.name(for: zoneClasses[1]) : BeaconObstacleDetector.name(for: zoneClasses[4])
        if obstacleName == nil {
            obstacleName = "Obstacle"
        }
        
        // 2. If any of top mid or bottom mid have an obstacle and both top left and bottom left have no obstacles, move left.
        if (zones[1] || zones[4]) && !zones[0] && !zones[3] {
            return "\(obstacleName!) ahead, move left."
        }
        
        // 3. If any of top mid or bottom mid have an obstacle and both top right and bottom right have no obstacles, move right.
        if (zones[1] || zones[4]) && !zones[2] && !zones[5] {
            return "\(obstacleName!) ahead, move right."
        }
        
        // 4. Otherwise, stop.
        return "\(obstacleName!) ahead, stop."
    }

    
    // MARK: - Utilities
    
    private static let classNames: [String] = [
        "Wall", "Building", "Sky", "Floor", "Tree", "Ceiling", "Road", "Bed", "Window", "Grass",
        "Cabinet", "Sidewalk", "Person", "Ground", "Door", "Table", "Mountain", "Plant", "Curtain", "Chair",
        "Car", "Water", "Painting", "Sofa", "Shelf", "House", "Sea", "Mirror", "Carpet", "Field",
        "Armchair", "Seat", "Fence", "Desk", "Rock", "Wardrobe", "Lamp", "Bathtub", "Railing", "Cushion",
        "Stand", "Box", "Pillar", "Signboard", "Chest", "Counter", "Sand", "Sink", "Skyscraper", "Fireplace",
        "Refrigerator", "Grandstand", "Path", "Stairs", "Runway", "Case", "Pool", "Pillow", "Screen Door", "Stairway",
        "River", "Bridge", "Bookcase", "Blind", "Small Table", "Toilet", "Flower", "Book", "Hill", "Bench",
        "Countertop", "Stove", "Palm", "Kitchen", "Computer", "Swivel", "Boat", "Bar", "Arcade", "Hovel",
        "Bus", "Towel", "Light", "Truck", "Tower", "Chandelier", "Awning", "Streetlight", "Booth", "Television",
        "Airplane", "Dirt", "Apparel", "Pole", "Land", "Bannister", "Escalator", "Ottoman", "Bottle", "Buffet",
        "Poster", "Stage", "Van", "Ship", "Fountain", "Conveyor", "Canopy", "Washer", "Plaything", "Swimming Pool",
        "Stool", "Barrel", "Basket", "Waterfall", "Tent", "Bag", "Minibike", "Cradle", "Oven", "Ball",
        "Food", "Step", "Tank", "Trade", "Microwave", "Pot", "Animal", "Bicycle", "Lake", "Dishwasher",
        "Screen", "Blanket", "Sculpture", "Hood", "Sconce", "Vase", "Traffic Light", "Tray", "Trash Can", "Fan",
        "Pier", "Screen", "Plate", "Monitor", "Bulletin Board", "Shower", "Radiator", "Glass", "Clock", "Flag"
    ]
    
    /// Get class name from ADE20K ID.
    static func name(for id: Int) -> String? {
        guard id >= 0 && id < classNames.count else { return nil }
        return classNames[id]
    }
    
    /// Converts a CGImage into a CVPixelBuffer of given dimensions (BGRA).
    private func pixelBuffer(from cgImage: CGImage,
                             width: Int,
                             height: Int) -> CVPixelBuffer? {
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        var pixelBufferOptional: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &pixelBufferOptional
        )
        guard status == kCVReturnSuccess, let pixelBuffer = pixelBufferOptional else {
            return nil
        }
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
        
        let ciContext = CIContext(options: nil)
        let ciImage = CIImage(cgImage: cgImage)
        let transform = CGAffineTransform(
            scaleX: CGFloat(width) / CGFloat(cgImage.width),
            y: CGFloat(height) / CGFloat(cgImage.height)
        )
        let scaled = ciImage.transformed(by: transform)
        ciContext.render(scaled, to: pixelBuffer)
        return pixelBuffer
    }
}
