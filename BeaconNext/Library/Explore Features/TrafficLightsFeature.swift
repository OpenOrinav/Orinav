import CoreML
import Vision

enum TrafficLightType: String, CaseIterable, Codable {
    case green = "green"
    case red = "red"
}

struct TrafficLight {
    var type: TrafficLightType
    var size: CGSize
    var countdown: Int?
}

class TrafficLightsFeature {
    var frameHandler: FrameHandler
    
    private let visionModel: VNCoreMLModel
    private let greenModel: VNCoreMLModel
    private let redModel: VNCoreMLModel
    private let countdownModel: VNCoreMLModel
    
    private var detectionTask: Task<Void, Never>?
    
    let validGreenLabelsG = ["绿灯CN", "绿灯USA", "读秒绿灯", "读秒USA"]
    let validRedLabelsR = ["红灯CN", "红灯USA", "读秒", "读秒USA"]
    let countdownLabels = ["读秒绿灯", "读秒USA", "读秒"]
    
    init?(frameHandler: FrameHandler) {
        self.frameHandler = frameHandler
        
        // Load pre-compiled models
        let config = MLModelConfiguration()
        config.computeUnits = .all
        config.allowLowPrecisionAccumulationOnGPU = true
        
        visionModel = try! VNCoreMLModel(for: yolo11n().model)
        greenModel = try! VNCoreMLModel(for: MLModel(contentsOf: Bundle.main.url(forResource: "yolo11s-cls-green", withExtension: "mlmodelc")!, configuration: config))
        redModel = try! VNCoreMLModel(for: MLModel(contentsOf: Bundle.main.url(forResource: "yolo11s-cls-red", withExtension: "mlmodelc")!, configuration: config))
        countdownModel = try! VNCoreMLModel(for: MLModel(contentsOf: Bundle.main.url(forResource: "yolo11s-cls-countdown", withExtension: "mlmodelc")!, configuration: config))
        
        startDetection()
    }
    
    // Convert Vision normalized bbox (origin at bottom-left) to CGImage pixel rect (origin at top-left)
    private func pixelRect(from normalizedRect: CGRect, image: CGImage) -> CGRect {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let x = normalizedRect.origin.x * width
        let y = (1.0 - normalizedRect.origin.y - normalizedRect.size.height) * height
        let w = normalizedRect.size.width * width
        let h = normalizedRect.size.height * height
        return CGRect(x: x, y: y, width: w, height: h)
    }
    
    private func findTrafficLights(from image: CGImage) async throws -> [TrafficLight] {
        // First, find the traffic lights. TODO Add a confidence threshold
        let lights: [VNRecognizedObjectObservation] = try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: visionModel) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                var validLights: [VNRecognizedObjectObservation] = []
                for observation in request.results ?? [] {
                    guard let obj = observation as? VNRecognizedObjectObservation else { continue }
                    if let topLabel = obj.labels.first, topLabel.identifier == "traffic light" {
                        validLights.append(obj)
                    }
                }
                continuation.resume(returning: validLights)
            }
            
            let handler = VNImageRequestHandler(cgImage: image)
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
        
        // Then, cut the image to the bounding box of traffic lights
        let lightsImages: [CGImage] = lights.compactMap { light in
            image.cropping(to: pixelRect(from: light.boundingBox, image: image))
        }
        
        guard let thisLightImage = lightsImages.first else { return [] } // for testing just pick one
        
        // Determine type
        let greenObv: VNClassificationObservation? = try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: self.greenModel) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                if let results = request.results as? [VNClassificationObservation], !results.isEmpty {
                    continuation.resume(returning: results.first)
                } else {
                    continuation.resume(returning: nil)
                }
            }
            
            let handler = VNImageRequestHandler(cgImage: thisLightImage)
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
        
        let redObv: VNClassificationObservation? = try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: self.redModel) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                if let results = request.results as? [VNClassificationObservation], !results.isEmpty {
                    continuation.resume(returning: results.first)
                } else {
                    continuation.resume(returning: nil)
                }
            }
            
            let handler = VNImageRequestHandler(cgImage: thisLightImage)
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
        
        // Two models make predictions
        guard let greenObv = greenObv, let redObv = redObv else { return [] }
        
        // BEGIN DEBUG
        let aID = greenObv.identifier
        let bID = redObv.identifier
        DispatchQueue.main.async {
            BeaconTTSService.shared
                .speak(
                    "绿: \(aID)，红: \(bID)",
                    type: .explore,
                    language: "zh-CN"
                )
        }
        // END DEBUG
        
        var type: TrafficLightType = .green
        var identifier: String
        if validGreenLabelsG.contains(greenObv.identifier) {
            type = .green
            identifier = greenObv.identifier
        } else if validRedLabelsR.contains(redObv.identifier) {
            type = .red
            identifier = redObv.identifier
        } else {
            return []
        }
        
        // If identified as countdown light, perform another model to get the countdown number
        if countdownLabels.contains(identifier) {
            let countdownObv: VNClassificationObservation? = try await withCheckedThrowingContinuation { continuation in
                let request = VNCoreMLRequest(model: self.countdownModel) { request, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    if let results = request.results as? [VNClassificationObservation], !results.isEmpty {
                        continuation.resume(returning: results.first)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
                
                let handler = VNImageRequestHandler(cgImage: thisLightImage)
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            if let countdownObv = countdownObv {
                if let number = Int(countdownObv.identifier) {
                    return [TrafficLight(type: type, size: CGSize(width: thisLightImage.width, height: thisLightImage.height), countdown: number)]
                }
            }
        }
        
        // Return the detected traffic light
        return [TrafficLight(type: type, size: CGSize(width: thisLightImage.width, height: thisLightImage.height), countdown: nil)]
    }
    
    private func startDetection() {
        detectionTask?.cancel()
        detectionTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { return }
                guard let frame = self.frameHandler.frame else { continue }
                let lights = (try? await findTrafficLights(from: frame)) ?? []
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
        }
    }
    
    func disable() {
        detectionTask?.cancel()
        detectionTask = nil
    }
}
