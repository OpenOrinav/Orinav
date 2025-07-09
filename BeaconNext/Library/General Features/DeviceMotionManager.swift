import Foundation
import CoreMotion
import CoreLocation
import Combine
import UIKit

final class DeviceMotionManager: ObservableObject {
    static let shared = DeviceMotionManager()
    
    private let motionManager = CMMotionManager()
    var delegates: [DeviceMotionDelegate] = []

    @Published var isPhoneRaised = false

    private init() {
        startMonitoring()
    }

    func startMonitoring() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 0.2
        motionManager.startDeviceMotionUpdates(to: .main) { motion, error in
            guard let motion = motion else { return }

            let pitch = motion.attitude.pitch * 180 / .pi
            let roll = motion.attitude.roll * 180 / .pi
            
            if pitch > 55 && abs(roll) < 45 {
                self.isPhoneRaised = true
                self.delegates.forEach { $0.didRaise() }
            } else {
                self.isPhoneRaised = false
                self.delegates.forEach { $0.didLower() }
            }
        }
    }

    func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
    }
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            DeviceMotionManager.shared.delegates.forEach { $0.didShake() }
        }
    }
}
