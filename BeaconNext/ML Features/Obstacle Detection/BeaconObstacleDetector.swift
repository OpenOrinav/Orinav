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
    
    // MARK: - Metal
    private let metalDevice: MTLDevice? = MTLCreateSystemDefaultDevice()
    private let argmaxPipeline: MTLComputePipelineState?
    
    init() {
        if let device = metalDevice,
           let defaultLibrary = device.makeDefaultLibrary(),
           let kernelFunc = defaultLibrary.makeFunction(name: "argmaxAcrossChannels") {
            do {
                argmaxPipeline = try device.makeComputePipelineState(function: kernelFunc)
            } catch {
                fatalError("Failed to create Metal compute pipeline: \(error)")
            }
        } else {
            fatalError("Metal device or pipeline creation failed")
        }
        
    }
    
    // MARK: - UI Update
    
    @Published var obstacleImage: CGImage?
    @Published var originalImage: CGImage?
    
    /// Main entry: run segmentation + disparity + obstacle masking
    func detect(_ inputImage: CGImage, frame: Int) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.detectObstacles(from: inputImage)
            print("Processed frame \(frame)")
            DispatchQueue.main.async {
                self.obstacleImage = result
            }
        }
    }
    
    var lastProfile: Date?
    
    func profileStart(_ name: String) {
        lastProfile = Date()
        print("Started profiling \(name)")
    }
    
    func profileEnd(_ name: String) {
        guard let start = lastProfile else {
            print("No profile start for \(name)")
            return
        }
        let duration = Date().timeIntervalSince(start)
        print("Finished profiling \(name) in \(duration * 1000) ms")
    }
    
    // MARK: - Main Algorithm
    
    private func detectObstacles(from image: CGImage) -> CGImage? {
        // 1. Create pixel buffers for CoreML inputs
        guard
            let segBuffer = pixelBuffer(from: image, width: segWidth, height: segHeight),
            let depthBuffer = pixelBuffer(from: image, width: depthWidth, height: depthHeight)
        else {
            return nil
        }
        
        // BEGIN DEBUG
        // Resize and set originalImage
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        if let context = CGContext(
            data: nil,
            width: segWidth,
            height: segHeight,
            bitsPerComponent: image.bitsPerComponent,
            bytesPerRow: segWidth * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) {
            context.draw(image, in: CGRect(x: 0, y: 0, width: segWidth, height: segHeight))
            if let resized = context.makeImage() {
                DispatchQueue.main.async {
                    self.originalImage = resized
                }
            }
        }
        // END DBEUG
        
        // 2. Run TopFormer (segmentation)
        guard let segOutput = try? topFormer.prediction(input_image: segBuffer) else {
            return nil
        }
        let segmentation = computeArgmax(semMap: segOutput.var_1347)  // [262144]
        guard let segmentation = segmentation else {
            return nil
        }
        
        var finalLabels = [Int32](repeating: 0, count: segPixels)
        
        for label in Set(finalLabels) {
            print(label)
        }

        // 2.1 Calculate connected components
        segmentation.withUnsafeBufferPointer { segPtr in
            finalLabels.withUnsafeMutableBufferPointer { outPtr in
                c_connected_components(
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
    
        /*

        // 4. Now compute per-component max disparity and classThe same as before:
        var maxDisp = [Float](repeating: -Float.greatestFiniteMagnitude, count: segPixels)
        var classLabel = [Int32](repeating: -1, count: segPixels)
        let globalMaxDisp = dispUpsampled.max() ?? 0
        let threshold = thresholdDisparity * globalMaxDisp
        
        for i in 0..<segPixels {
            let root = finalLabels[i]
            let label = segmentation[i]
            let d = dispUpsampled[i]
            if classLabel[root] < 0 {
                classLabel[root] = label
            }
            if d > maxDisp[root] {
                maxDisp[root] = d
            }
        }
        
        var valid = [Bool](repeating: false, count: segPixels)
        for i in 0..<segPixels {
            let root = finalLabels[i]
            if !ignoredClassIDs.contains(classLabel[root]) && maxDisp[root] > threshold {
                valid[i] = true
            }
        }
        
        // Build output mask
        let maskBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: segPixels)
        for i in 0..<segPixels {
            let root = finalLabels[i]
            maskBytes[i] = valid[root] ? 255 : 0
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
         */
        
        let maskBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: segPixels)
        let maxLabel = finalLabels.max() ?? 1
        for i in 0..<segPixels {
            maskBytes[i] = UInt8((finalLabels[i] / maxLabel) * 255)
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
    
    /// Use Metal to compute argmax over TopFormer logits.
    private func computeArgmax(semMap: MLMultiArray) -> [Int32]? {
        guard
            let device = metalDevice,
            let pipeline = argmaxPipeline
        else {
            return nil
        }
        
        let shape = semMap.shape.map { $0.intValue }
        guard shape == [1, 150, 512, 512] else {
            print("Unexpected semMap shape: \(shape)")
            return nil
        }
        let pixelCount = shape[2] * shape[3]    // 512*512
        let channelCount = shape[1]            // 150
        
        var floatPtr: UnsafePointer<Float>!
        semMap.withUnsafeBytes { rawBuffer in
            floatPtr = rawBuffer.bindMemory(to: Float.self).baseAddress!
        }
        
        let lengthInBytes = channelCount * pixelCount * MemoryLayout<Float>.stride
        guard let inBuffer = device.makeBuffer(
            bytesNoCopy: UnsafeMutableRawPointer(mutating: floatPtr),
            length: lengthInBytes,
            options: .storageModeShared,
            deallocator: nil)
        else {
            print("Failed to create Metal input buffer")
            return nil
        }
        
        let outLength = pixelCount * MemoryLayout<Int32>.stride
        guard let outBuffer = device.makeBuffer(
            length: outLength,
            options: .storageModeShared)
        else {
            print("Failed to create Metal output buffer")
            return nil
        }
        
        guard let commandQueue = device.makeCommandQueue(),
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder()
        else {
            print("Failed to create Metal command encoder")
            return nil
        }
        
        encoder.setComputePipelineState(pipeline)
        encoder.setBuffer(inBuffer, offset: 0, index: 0)
        encoder.setBuffer(outBuffer, offset: 0, index: 1)
        
        var pc: UInt32 = UInt32(pixelCount)
        var cc: UInt32 = UInt32(channelCount)
        encoder.setBytes(&pc, length: MemoryLayout<UInt32>.stride, index: 2)
        encoder.setBytes(&cc, length: MemoryLayout<UInt32>.stride, index: 3)
        
        let threadsPerThreadgroup = MTLSize(width: 256, height: 1, depth: 1)
        let threadGroups = MTLSize(
            width: (pixelCount + 255) / 256,
            height: 1,
            depth: 1)
        
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadsPerThreadgroup)
        encoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        let outPtr = outBuffer.contents().bindMemory(to: Int32.self, capacity: pixelCount)
        let bufferPointer = UnsafeBufferPointer(start: outPtr, count: pixelCount)
        return Array(bufferPointer)
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
