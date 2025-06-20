import Foundation
import UIKit
import CoreHaptics

class HapticsManager {
    enum FeedbackType {
        case success
        case warning
        case error
    }
    
    static func NotificationHaptic(for type: FeedbackType) {
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.prepare()

        switch type {
        case .success:
            notificationGenerator.notificationOccurred(.success)
        case .warning:
            notificationGenerator.notificationOccurred(.warning)
        case .error:
            notificationGenerator.notificationOccurred(.error)
        }
    }
    
    static func impactHaptic(for intensity: Double) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }
    
    static func correctDir() {
        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactGenerator.prepare()

        let delays: [Double] = [0.2, 0.4, 0.5]

        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                impactGenerator.impactOccurred(intensity: 1.0)
            }
        }
    }
}
