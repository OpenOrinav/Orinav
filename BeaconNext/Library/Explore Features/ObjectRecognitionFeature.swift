import Vision

class ObjectRecognitionFeature {
    var frameHandler: FrameHandler
    private let visionModel: VNCoreMLModel
    
    private var detectionTask: Task<Void, Never>?
    private var previousObjects: [String] = []
    
    init?(frameHandler: FrameHandler) {
        self.frameHandler = frameHandler
        guard let model = try? VNCoreMLModel(for: yolo11n().model) else {
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
                    guard error == nil else { return }
                    var detectedObjects: [String: CGFloat] = [:]
                    for observation in request.results ?? [] {
                        guard let obj = observation as? VNRecognizedObjectObservation else { continue }
                        if let topLabel = obj.labels.first {
                            detectedObjects[topLabel.identifier] = obj.boundingBox.width * obj.boundingBox.height
                        }
                    }
                    
                    // Sort and take top three objects largest in view
                    let sortedObjects = detectedObjects.sorted { $0.value > $1.value }
                    let string = sortedObjects.prefix(3).map { $0.key }
                    if string != self.previousObjects {
                        self.previousObjects = string
                        DispatchQueue.main.async {
                            BeaconTTSService.shared.speak(string.map { NSLocalizedString($0, comment: "") }.joined(separator: ","), type: .explore)
                        }
                    }

                }
                
                guard let frame = frameHandler.frame else { continue }
                let requestHandler = VNImageRequestHandler(cgImage: frame)
                do {
                    try requestHandler.perform([request])
                } catch {
                    print("Obstacle detection failed: \(error)")
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
