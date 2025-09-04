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
    
    let confidenceThreshold: Float = 0.75
    let defocusCycles = 10
    
    private let visionModel: VNCoreMLModel
    private let greenModel: VNCoreMLModel
    private let redModel: VNCoreMLModel
    private let countdownModel: VNCoreMLModel
    
    private var detectionTask: Task<Void, Never>?
    private var soundTask: Task<Void, Never>?
    
    private var trafficLights: [TrafficLight] = []
    
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
        startSoundPlayback()
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
        // First, find the traffic lights.
        let lights: [VNRecognizedObjectObservation] = try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: visionModel) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                var validLights: [VNRecognizedObjectObservation] = []
                for observation in request.results ?? [] {
                    guard let obj = observation as? VNRecognizedObjectObservation else { continue }
                    if let topLabel = obj.labels.first, topLabel.identifier == "traffic light", topLabel.confidence >= self.confidenceThreshold {
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
        
        if lights.isEmpty {
            return []
        }
        
        // Then, cut the image to the bounding box of traffic lights
        let lmTmp: [CGImage] = lights.compactMap { light in
            image.cropping(to: pixelRect(from: light.boundingBox, image: image))
        }
        
        // Order lights by size
        let lightsImages = zip(lights, lmTmp).sorted { (a, b) in
            let areaA = a.0.boundingBox.width * a.0.boundingBox.height
            let areaB = b.0.boundingBox.width * b.0.boundingBox.height
            return areaA > areaB
        }

        // Focus on the first, and also the nearest, light
        frameHandler.focus(x: lights.first!.boundingBox.midX, y: lights.first!.boundingBox.midY)
        
        var result: [TrafficLight] = []
        // Determine type for each light
        for (_, lightImage) in lightsImages {
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
                
                let handler = VNImageRequestHandler(cgImage: lightImage)
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
                
                let handler = VNImageRequestHandler(cgImage: lightImage)
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            // Two models make predictions
            guard let greenObv = greenObv, let redObv = redObv else { continue }
            
            var type: TrafficLightType = .green
            if greenObv.identifier != " " && greenObv.identifier != "红灯CN" {
                type = .green
            } else if redObv.identifier != " " && redObv.identifier != "绿灯CN" {
                type = .red
            } else {
                continue // Invalid traffic light, skip
            }
            
            // Another model for countdown extraction
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
                
                let handler = VNImageRequestHandler(cgImage: lightImage)
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            if let countdownObv = countdownObv {
                if let number = Int(countdownObv.identifier) {
                    result.append(TrafficLight(type: type, size: CGSize(width: lightImage.width, height: lightImage.height), countdown: number))
                    continue
                }
            }

            // Add the detected traffic light
            result.append(TrafficLight(type: type, size: CGSize(width: lightImage.width, height: lightImage.height), countdown: nil))
        }
        return result
    }
    
    private func startDetection() {
        detectionTask?.cancel()
        detectionTask = Task { [weak self] in
            var emptyCycles = 0
            
            self?.frameHandler.zoom(2)

            while !Task.isCancelled {
                guard let self = self else { return }
                guard let frame = self.frameHandler.frame else { continue }
                
                let lights = (try? await findTrafficLights(from: frame)) ?? []
                if lights.isEmpty {
                    emptyCycles += 1
                } else {
                    emptyCycles = 0
                }
                // Defocus if no traffic lights detected for a while
                if emptyCycles >= defocusCycles {
                    self.frameHandler.cancelFocus()
                }
                
                trafficLights = lights
                
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }

            self?.frameHandler.zoom(1)
            self?.frameHandler.cancelFocus() // Defocus when task ends
        }
    }
    
    private func startSoundPlayback() {
        soundTask?.cancel()
        soundTask = Task { [weak self] in
            var cycle = true
            
            while !Task.isCancelled {
                guard let self = self else { return }
                guard let nearest = self.trafficLights.first else { continue }
                
                DispatchQueue.main.async {
                    if nearest.type == .red {
                        SoundEffectsManager.shared.playRed()
                        if cycle {
                            BeaconTTSService.shared.speak(String(localized: "Red"), type: .explore)
                        }
                    } else {
                        SoundEffectsManager.shared.playGreen()
                        if cycle {
                            BeaconTTSService.shared.speak(String(localized: "Green"), type: .explore)
                        }
                    }
                    
                    cycle = !cycle // Only speak every other time so the user can actually hear the sound
                }
                if let countdown = nearest.countdown, cycle {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.59) { // Matches second tap in sound
                        BeaconTTSService.shared.speak(String(countdown), type: .explore)
                    }
                }
                
                try? await Task.sleep(nanoseconds: 1_225_000_000) // 1.175 + 0.05 seconds so it loops smoothly
            }
        }
    }
    
    func disable() {
        detectionTask?.cancel()
        soundTask?.cancel()
        detectionTask = nil
        soundTask = nil
        self.frameHandler.zoom(1)
        self.frameHandler.cancelFocus()
    }
}
