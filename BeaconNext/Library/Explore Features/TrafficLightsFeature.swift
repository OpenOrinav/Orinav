import Vision

class TrafficLightsFeature {
    var frameHandler: FrameHandler
    private let visionModel: VNCoreMLModel
    
    private var detectionTask: Task<Void, Never>?
    
    init?(frameHandler: FrameHandler) {
        self.frameHandler = frameHandler
        guard let model = try? VNCoreMLModel(for: yoloTrafficLight().model) else {
            return nil
        }
        self.visionModel = model
        
        startDetection()
    }

    private func startDetection() {
        detectionTask?.cancel()
        detectionTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { return }
                
                let request = VNCoreMLRequest(model: self.visionModel) { request, error in
                    guard error == nil, let results = request.results else { return }
                    if results.isEmpty { print("Empty"); return }
                    let obv = results.first as! VNRecognizedObjectObservation
                    print(obv.labels.first!.identifier)
                    DispatchQueue.main.async {
                        BeaconTTSService.shared.speak(obv.labels.first!.identifier, type: .explore)
                    }
                }
                
                guard let frame = frameHandler.frame else { continue }
                let requestHandler = VNImageRequestHandler(cgImage: frame)
                do {
                    try requestHandler.perform([request])
                } catch {
                    print("Traffic light detection failed: \(error)")
                }
                
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
        }
    }
    
    func disable() {
        detectionTask?.cancel()
        detectionTask = nil
    }
}
