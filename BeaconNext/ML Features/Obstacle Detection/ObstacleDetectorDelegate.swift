import Combine
import UIKit

class ObstacleDetectorDelegate: DeviceMotionDelegate {
    let obstacleDetector: BeaconObstacleDetector
    var delay: Float = 1.5
    var style: UIImpactFeedbackGenerator.FeedbackStyle = .light

    private var distanceCancellable: AnyCancellable?
    private var hapticTask: Task<Void, Never>?

    init(obstacleDetector: BeaconObstacleDetector) {
        self.obstacleDetector = obstacleDetector
        self.startHaptics()
        distanceCancellable = obstacleDetector.$keyDistance
            .sink { [weak self] distance in
                guard let distance = distance else { return }
                
                if distance <= 1 {
                    self?.style = .heavy
                } else if distance <= 2 {
                    self?.style = .medium
                } else {
                    self?.style = .light
                }
                
                if distance >= 3 {
                    self?.delay = 1.5
                } else {
                    // 1.5 to 0.1 from 3 to 0
                    self?.delay = (1.4 / 3) * distance + 0.1
                }
            }
    }

    func didShake() {
        Task { @MainActor in
            BeaconTTSService.shared.speak(obstacleDetector.message, type: .explore)
        }
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
                let generator = UIImpactFeedbackGenerator(style: style)
                generator.prepare()
                generator.impactOccurred()
                
                // Wait
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }

    deinit {
        distanceCancellable?.cancel()
        hapticTask?.cancel()
    }
}
