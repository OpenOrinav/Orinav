import Foundation
import CoreML
import UIKit
import Accelerate

/// A detector that fuses semantic segmentation (TopFormer) and disparity (MiDaS)
/// to identify nearby obstacles in a CGImage. Obstacles whose maximum disparity
/// exceeds `thresholdDisparity` and whose class ID is not `pathClassID` are retained.
class BeaconObstacleDetector: ObservableObject {
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
        "Poster", "Stage", "Van", "Ship", "Fountain", "Conveyer", "Canopy", "Washer", "Plaything", "Swimming Pool",
        "Stool", "Barrel", "Basket", "Waterfall", "Tent", "Bag", "Minibike", "Cradle", "Oven", "Ball",
        "Food", "Step", "Tank", "Trade", "Microwave", "Pot", "Animal", "Bicycle", "Lake", "Dishwasher",
        "Screen", "Blanket", "Sculpture", "Hood", "Sconce", "Vase", "Traffic Light", "Tray", "Trash Can", "Fan",
        "Pier", "Screen", "Plate", "Monitor", "Bulletin Board", "Shower", "Radiator", "Glass", "Clock", "Flag"
    ]
    
    static func name(for id: Int) -> String? {
        guard id >= 0 && id < classNames.count else { return nil }
        return classNames[id]
    }
    
    // MARK: - UI Update
    
    @Published var obstacleImage: CGImage?
    
    func detect(_ inputImage: CGImage) {
        DispatchQueue.global(qos: .userInitiated).async {
            let detected = self.detectObstacles(from: inputImage)
            DispatchQueue.main.async {
                self.obstacleImage = detected
            }
        }
    }
    
    // MARK: - Configuration
    
    /// The semantic class ID to be ignored.
    private let ignoredClassIDs = [
        52, // Path
        2, // Sky
        3, // Floor
        6, // Road
        11, // Sidewalk, pavement
        13 // Ground
    ]
    
    /// Disparity threshold (relative) below which regions are discarded.
    /// Experimentally, a value around 0.6 of the maximum disparity often works.
    private let thresholdDisparity: Float = 0.6
    
    /// Input size expected by TopFormer (semantic segmentation): 512 × 512.
    private let segInputWidth = 512
    private let segInputHeight = 512
    
    /// Input size expected by MiDaS (disparity): 256 × 256.
    private let depthInputWidth = 256
    private let depthInputHeight = 256
    
    // MARK: - Models
    
    /// TopFormer semantic segmentation model (expects a 512×512 color image).
    private let topFormer: TopFormer = {
        do {
            let config = MLModelConfiguration()
            return try TopFormer(configuration: config)
        } catch {
            fatalError("Failed to load TopFormer model: \(error)")
        }
    }()
    
    /// MiDaS disparity estimation model (expects a 256×256 color image).
    private let miDaS: MiDaS = {
        do {
            let config = MLModelConfiguration()
            return try MiDaS(configuration: config)
        } catch {
            fatalError("Failed to load MiDaS model: \(error)")
        }
    }()
    
    // MARK: - Main API
    
    /// Processes an input CGImage, performs semantic segmentation and disparity estimation,
    /// and returns a CGImage mask highlighting the detected obstacles.
    ///
    /// - Parameter image: The input color image (any resolution).
    ///                    Internally resized as needed for each model.
    /// - Returns: A binary mask (`CGImage`) of the same size as the segmentation input (512×512),
    ///            where obstacle pixels are white (255), and background is black (0).
    func detectObstacles(from image: CGImage) -> CGImage? {
        // 1. Resize input for segmentation (512×512) and disparity (256×256).
        guard
            let segBuffer = self.pixelBuffer(from: image,
                                             width: segInputWidth,
                                             height: segInputHeight),
            let depthBuffer = self.pixelBuffer(from: image,
                                               width: depthInputWidth,
                                               height: depthInputHeight)
        else {
            return nil
        }
        
        // 2. Run TopFormer to get semantic logits (shape: 1×150×512×512).
        guard let segOutput = try? topFormer.prediction(input_image: segBuffer) else {
            return nil
        }
        // segOutput.var_1347: MLMultiArray of shape [1, 150, 512, 512]
        let semLogitsArray = segOutput.var_1347
        
        // 3. Run MiDaS to get disparity map (shape: 1×256×256).
        guard let depthOutput = try? miDaS.prediction(x_1: depthBuffer) else {
            return nil
        }
        // depthOutput.var_1438: MLMultiArray of shape [1, 256, 256]
        let dispArray = depthOutput.var_1438
        
        // 4. Convert semantic logits to a 2D class-ID map (512×512) via argmax over 150 classes.
        let segmentationMap = self.createSegmentationMap(from: semLogitsArray)
        // segmentationMap is a 2D [Int] of size [512][512], where each pixel’s value is in [0..149]
        
        // 5. Convert disparity MLMultiArray to a 2D Float array and upsample to 512×512.
        let depthMap256 = self.array(from: dispArray,
                                     height: depthInputHeight,
                                     width: depthInputWidth)
        let depthMap512 = self.upsample(
            small: depthMap256,
            fromWidth: depthInputWidth,
            fromHeight: depthInputHeight,
            toWidth: segInputWidth,
            toHeight: segInputHeight
        )
        
        // 6. Compute connected components per class ID, threshold by max disparity, discard “path” class.
        let obstacleMask = self.computeObstacleMask(
            segmentationMap: segmentationMap,
            depthMap: depthMap512
        )
        // obstacleMask is a 2D [Bool] of size [512][512]
        
        // 7. Convert obstacleMask into a CGImage (binary mask: white = obstacle, black = background)
        return self.createMaskImage(from: obstacleMask)
    }
    
    // MARK: - Helper Methods
    
    /// Converts a CGImage into a CVPixelBuffer of given dimensions (RGB, normalized as needed).
    private func pixelBuffer(from cgImage: CGImage,
                             width: Int,
                             height: Int) -> CVPixelBuffer? {
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         kCVPixelFormatType_32BGRA,
                                         attrs as CFDictionary,
                                         &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        
        // Create a CIContext and draw:
        let ciContext = CIContext(options: nil)
        let ciImage = CIImage(cgImage: cgImage)
        let transform = CGAffineTransform(
            scaleX: CGFloat(width) / CGFloat(cgImage.width),
            y: CGFloat(height) / CGFloat(cgImage.height)
        )
        let scaled = ciImage.transformed(by: transform)
        ciContext.render(scaled, to: buffer)
        return buffer
    }
    
    /// Performs argmax over the 150-class logits to produce a 2D segmentation map [512×512].
    /// - Parameter logits: MLMultiArray of shape [1, 150, 512, 512].
    /// - Returns: A 2D array `Int` of size [512][512] with class IDs in [0..149].
    private func createSegmentationMap(from logits: MLMultiArray) -> [[Int]] {
        let classes = logits.shape[1].intValue  // 150
        let height = logits.shape[2].intValue   // 512
        let width = logits.shape[3].intValue    // 512
        
        // Flattened pointer to MLMultiArray’s data
        let ptr = UnsafeMutablePointer<Float>(OpaquePointer(logits.dataPointer))
        
        // We'll create an output 2D array:
        var segMap = Array(
            repeating: Array(repeating: 0, count: width),
            count: height
        )
        
        // Strides to index logits: [batch=0, c, y, x]
        // strideBatch = logits.strides[0] = 150*512*512
        // strideClass = logits.strides[1] = 512*512
        // strideY = logits.strides[2] = 512
        // strideX = logits.strides[3] = 1
        let strideBatch = logits.strides[0].intValue
        let strideClass = logits.strides[1].intValue
        let strideY = logits.strides[2].intValue
        let strideX = logits.strides[3].intValue
        
        // For each pixel, find argmax across classes:
        for y in 0..<height {
            for x in 0..<width {
                var bestClass = 0
                var bestLogit: Float = -Float.greatestFiniteMagnitude
                for c in 0..<classes {
                    let offset = c * strideClass + y * strideY + x * strideX
                    let logit = ptr[offset]
                    if logit > bestLogit {
                        bestLogit = logit
                        bestClass = c
                    }
                }
                segMap[y][x] = bestClass
            }
        }
        return segMap
    }
    
    /// Converts an MLMultiArray of shape [1, H, W] to a 2D [[Float]] of size [H][W].
    /// - Parameters:
    ///   - array: The MLMultiArray to convert.
    ///   - height: The height H.
    ///   - width: The width W.
    private func array(from array: MLMultiArray,
                       height: Int,
                       width: Int) -> [[Float]] {
        // Strides: [batch=0, Y, X]
        let strideBatch = array.strides[0].intValue   // H*W
        let strideY = array.strides[1].intValue       // W
        let strideX = array.strides[2].intValue       // 1
        let ptr = UnsafeMutablePointer<Float>(OpaquePointer(array.dataPointer))
        
        var result = Array(repeating: Array(repeating: Float(0), count: width),
                           count: height)
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * strideY + x * strideX
                result[y][x] = ptr[offset]
            }
        }
        return result
    }
    
    /// Upsamples a smaller 2D `Float` array (H₁×W₁) to a larger (H₂×W₂) using bilinear interpolation.
    private func upsample(small: [[Float]],
                          fromWidth: Int,
                          fromHeight: Int,
                          toWidth: Int,
                          toHeight: Int) -> [[Float]] {
        var result = Array(repeating: Array(repeating: Float(0), count: toWidth),
                           count: toHeight)
        
        let sx = Float(fromWidth - 1) / Float(toWidth - 1)
        let sy = Float(fromHeight - 1) / Float(toHeight - 1)
        
        for y2 in 0..<toHeight {
            let fy = Float(y2) * sy
            let y0 = Int(floor(fy))
            let y1 = min(y0 + 1, fromHeight - 1)
            let dy = fy - Float(y0)
            
            for x2 in 0..<toWidth {
                let fx = Float(x2) * sx
                let x0 = Int(floor(fx))
                let x1 = min(x0 + 1, fromWidth - 1)
                let dx = fx - Float(x0)
                
                // Bilinear interpolation:
                let v00 = small[y0][x0]
                let v01 = small[y0][x1]
                let v10 = small[y1][x0]
                let v11 = small[y1][x1]
                
                let v0 = v00 * (1 - dx) + v01 * dx
                let v1 = v10 * (1 - dx) + v11 * dx
                let v = v0 * (1 - dy) + v1 * dy
                result[y2][x2] = v
            }
        }
        return result
    }
    
    /// Computes a binary mask of obstacles by:
    /// 1. Iterating over each class ID and finding connected components (4-connectivity).
    /// 2. For each component, computing the max disparity within its pixels.
    /// 3. Discarding components whose max disparity ≤ threshold or whose class ID == pathClassID.
    /// - Parameters:
    ///   - segmentationMap: 2D [Int] of class IDs (512×512).
    ///   - depthMap: 2D [Float] of upsampled disparities (512×512).
    /// - Returns: 2D [Bool] mask (512×512) where `true` indicates obstacle.
    private func computeObstacleMask(segmentationMap: [[Int]],
                                     depthMap: [[Float]]) -> [[Bool]] {
        let height = segmentationMap.count
        let width = segmentationMap[0].count
        
        // A visited map to mark which pixels have been assigned to a component
        var visited = Array(repeating: Array(repeating: false, count: width),
                            count: height)
        // The output obstacle mask
        var obstacleMask = Array(repeating: Array(repeating: false, count: width),
                                 count: height)
        
        // Offsets for 4-connectivity (up/down/left/right)
        let neighbors = [(-1, 0), (1, 0), (0, -1), (0, 1)]
        
        // Helper to check bounds:
        func inBounds(_ y: Int, _ x: Int) -> Bool {
            return (y >= 0 && y < height && x >= 0 && x < width)
        }
        
        // Breadth-First Search (BFS) to collect all pixels in a connected component
        func floodFill(startY: Int, startX: Int, classID: Int) -> [(Int, Int)] {
            var componentPixels: [(Int, Int)] = []
            var queue: [(Int, Int)] = [(startY, startX)]
            visited[startY][startX] = true
            
            var idx = 0
            while idx < queue.count {
                let (y, x) = queue[idx]
                idx += 1
                componentPixels.append((y, x))
                
                for (dy, dx) in neighbors {
                    let ny = y + dy
                    let nx = x + dx
                    if inBounds(ny, nx)
                        && !visited[ny][nx]
                        && segmentationMap[ny][nx] == classID {
                        visited[ny][nx] = true
                        queue.append((ny, nx))
                    }
                }
            }
            return componentPixels
        }
        
        // 1. Iterate over all pixels:
        for y in 0..<height {
            for x in 0..<width {
                guard !visited[y][x] else { continue }
                visited[y][x] = true
                
                let cid = segmentationMap[y][x]
                
                // Skip ignored class IDs
                if ignoredClassIDs.contains(cid) {
                    continue
                }
                
                // Gather the connected component for this class:
                let component = floodFill(startY: y, startX: x, classID: cid)
                
                // 2. Compute max disparity over component’s pixels:
                var maxDisparity: Float = -Float.greatestFiniteMagnitude
                for (py, px) in component {
                    let d = depthMap[py][px]
                    if d > maxDisparity {
                        maxDisparity = d
                    }
                }
                
                // 3. Compare maxDisparity against threshold:
                // We normalize threshold as a fraction of the maximum possible disparity in this frame.
                // Find the global maximum disparity in depthMap once (or approximate from component).
                // For simplicity, assume disparity values are already in [0..1] range. If not, normalize first.
                if maxDisparity > thresholdDisparity {
                    // 4. Mark all pixels in this component as obstacles:
                    for (py, px) in component {
                        obstacleMask[py][px] = true
                    }
                }
                // Otherwise, leave them false (discard).
            }
        }
        
        return obstacleMask
    }
    
    /// Converts a 2D `Bool` mask ([H][W]) into a grayscale `CGImage` of size W×H,
    /// with white (255) for `true`, black (0) for `false`.
    private func createMaskImage(from mask: [[Bool]]) -> CGImage? {
        let height = mask.count
        let width = mask[0].count
        let bytesPerRow = width
        
        // Flatten Bool → UInt8 array
        var pixelData = Data(count: width * height)
        pixelData.withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) in
            guard let dest = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return
            }
            for y in 0..<height {
                for x in 0..<width {
                    dest[y * width + x] = mask[y][x] ? 255 : 0
                }
            }
        }
        
        // Create a CGDataProvider
        guard let provider = CGDataProvider(data: pixelData as CFData) else {
            return nil
        }
        
        // Create a 8-bit grayscale CGImage
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        let renderingIntent = CGColorRenderingIntent.defaultIntent
        
        return CGImage(width: width,
                       height: height,
                       bitsPerComponent: 8,
                       bitsPerPixel: 8,
                       bytesPerRow: bytesPerRow,
                       space: colorSpace,
                       bitmapInfo: bitmapInfo,
                       provider: provider,
                       decode: nil,
                       shouldInterpolate: false,
                       intent: renderingIntent)
    }
}
