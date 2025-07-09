import Combine
import UIKit

class ObstacleDetectorFeature: ObservableObject, DeviceMotionDelegate {
    var frameHandler: FrameHandler
    
    @Published var message: String? = nil
    var previousMessage: String? = nil
    
    var delay: Double = 1.5
    var style: UIImpactFeedbackGenerator.FeedbackStyle = .light
    
    let heavyGen = UIImpactFeedbackGenerator(style: .heavy)
    let mediumGen = UIImpactFeedbackGenerator(style: .medium)
    let lightGen = UIImpactFeedbackGenerator(style: .light)
    
    private var depthCancellable: AnyCancellable?
    private var hapticTask: Task<Void, Never>?
    
    init(frameHandler: FrameHandler) {
        self.frameHandler = frameHandler
        heavyGen.prepare()
        mediumGen.prepare()
        lightGen.prepare()
        
        self.startHaptics()
        
        depthCancellable = frameHandler.$minDepth.sink { [weak self] distance in
            guard let distance = distance else { return }
            if distance <= 1 {
                self?.style = .heavy
            } else if distance <= 2 {
                self?.style = .medium
            } else {
                self?.style = .light
            }
            
            if distance >= 2 {
                self?.delay = 10
            } else {
                let minInterval: TimeInterval = 0.1
                let maxInterval: TimeInterval = 1.0
                let fraction = max(0, min(1, (distance - 0.7) / (5.0 - 0.7)))
                let interval = Double(0.05 + fraction * (1.0 - 0.05))
                self?.delay = max(minInterval, min(interval, maxInterval))
            }
        }
    }
    
    func didShake() {
        // TODO
    }
    
    private func startHaptics() {
        // Cancel any existing haptic loop
        hapticTask?.cancel()
        // Launch a repeating haptic loop
        hapticTask = Task { @MainActor in
            while !Task.isCancelled {
                if !BeaconExploreView.inExplore {
                    return
                }
                
                // Play haptic
                switch self.style {
                case .heavy:
                    heavyGen.impactOccurred()
                case .medium:
                    mediumGen.impactOccurred()
                case .light:
                    lightGen.impactOccurred()
                default:
                    break
                }
                
                // Wait
                // Ensure delay is a valid, finite, non-negative value
                let clampedDelay = delay.isFinite && delay >= 0 ? delay : 10
                try? await Task.sleep(nanoseconds: UInt64(clampedDelay * 1_000_000_000))
            }
        }
    }
    
    deinit {
        depthCancellable?.cancel()
        hapticTask?.cancel()
    }
}
