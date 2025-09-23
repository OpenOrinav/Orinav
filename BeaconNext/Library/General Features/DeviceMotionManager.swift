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

    // Shake detection heuristic
    private var lastShakeTime = Date.distantPast
    private var shakeCounter = 0
    private var shakeResetWorkItem: DispatchWorkItem?
    private let shakeCooldown: TimeInterval = 1.0      // minimum time between shakes
    private let shakeWindow: TimeInterval = 0.30       // window to accumulate shake samples
    private let shakeThreshold: Double = 1.3           // magnitude in g's (userAcceleration)
    private let shakeRequiredCount = 3                 // samples over threshold within window

    private init() {
        startMonitoring()
    }

    func startMonitoring() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 0.05
        motionManager.startDeviceMotionUpdates(to: .main) { motion, error in
            guard let motion = motion else { return }

            // = Detect shake gesture
            let ua = motion.userAcceleration
            let magnitude = sqrt(ua.x * ua.x + ua.y * ua.y + ua.z * ua.z)

            if magnitude > self.shakeThreshold {
                // start/reset the short accumulation window on first sample
                if self.shakeCounter == 0 {
                    self.shakeResetWorkItem?.cancel()
                    let wi = DispatchWorkItem { [weak self] in self?.shakeCounter = 0 }
                    self.shakeResetWorkItem = wi
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.shakeWindow, execute: wi)
                }
                self.shakeCounter += 1

                if self.shakeCounter >= self.shakeRequiredCount,
                   Date().timeIntervalSince(self.lastShakeTime) > self.shakeCooldown {
                    self.lastShakeTime = Date()
                    self.shakeCounter = 0
                    self.shakeResetWorkItem?.cancel()
                    self.delegates.forEach { $0.didShake() }
                }
            }

            // = Detect raise/lower gesture
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
        shakeResetWorkItem?.cancel()
        shakeResetWorkItem = nil
        shakeCounter = 0
    }
}

