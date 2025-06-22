import Foundation
import CoreMotion
import CoreLocation
import Combine

class DeviceMotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var isPhoneRaised = false

    init() {
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
            } else {
                self.isPhoneRaised = false
            }
        }
    }

    func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
    }
}
