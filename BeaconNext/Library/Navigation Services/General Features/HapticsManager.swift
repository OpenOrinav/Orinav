import Foundation
import UIKit

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
        let impactGenerator = UIImpactFeedbackGenerator()
        impactGenerator.impactOccurred(intensity: intensity)
    }
    
    static func correctDir() {
        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactGenerator.prepare()

//        let delays: [Double] = [0.1, 0.2, 0.5]

//        for delay in delays {
//            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
//                impactGenerator.impactOccurred(intensity: 0.5)
//            }
//        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            impactGenerator.impactOccurred(intensity: 0.7)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            impactGenerator.impactOccurred(intensity: 0.7)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            impactGenerator.impactOccurred(intensity: 1.0)
        }
        
        
    }
}
