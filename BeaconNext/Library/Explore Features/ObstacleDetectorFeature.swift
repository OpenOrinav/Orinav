import Combine
import UIKit

class ObstacleDetectorFeature {
    var frameHandler: FrameHandler
    
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
            if distance <= 0.5 {
                self?.style = .heavy
            } else if distance <= 1 {
                self?.style = .medium
            } else if distance <= 2 {
                self?.style = .light
            } else {
                self?.style = .soft // No haptics
            }
            
            if distance >= 2 {
                self?.delay = 2
            } else {
                let minInterval: TimeInterval = 0.1
                let maxInterval: TimeInterval = 1.0
                let fraction = max(0, min(1, (distance - 0.7) / (5.0 - 0.7)))
                let interval = Double(0.05 + fraction * (1.0 - 0.05))
                self?.delay = max(minInterval, min(interval, maxInterval))
            }
        }
    }
    
    private func startHaptics() {
        // Cancel any existing haptic loop
        hapticTask?.cancel()
        // Launch a repeating haptic loop
        hapticTask = Task { @MainActor [weak self] in
            var lastTime = Date()
            
            while !Task.isCancelled {
                guard let self = self else { return }
                if !BeaconExploreView.inExplore {
                    return
                }
                
                // If elapsed time is less than delay, skip this iteration
                let currentTime = Date()
                let elapsedTime = currentTime.timeIntervalSince(lastTime)
                if elapsedTime < delay {
                    try? await Task.sleep(nanoseconds: UInt64(100_000_000))
                    continue
                }
                lastTime = currentTime
                
                // Play haptic and sound
                switch self.style {
                case .heavy:
                    SoundEffectsManager.shared.playTapHigh()
                    heavyGen.impactOccurred()
                case .medium:
                    SoundEffectsManager.shared.playTapMid()
                    mediumGen.impactOccurred()
                case .light:
                    SoundEffectsManager.shared.playTapLow()
                    lightGen.impactOccurred()
                default:
                    break
                }
                try? await Task.sleep(nanoseconds: UInt64(100_000_000))
            }
        }
    }
    
    func disable() {
        depthCancellable?.cancel()
        hapticTask?.cancel()
        depthCancellable = nil
        hapticTask = nil
    }
}
