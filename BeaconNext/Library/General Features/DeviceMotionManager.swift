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

    // = Shake detection heuristic
    private var lastShakeTime = Date.distantPast
    private var shakeCounter = 0
    private var shakeResetWorkItem: DispatchWorkItem?
    private let shakeCooldown: TimeInterval = 1.0      // minimum time between shakes
    private let shakeWindow: TimeInterval = 0.30       // window to accumulate shake samples
    private let shakeThreshold: Double = 1.3           // magnitude in g's (userAcceleration)
    private let shakeRequiredCount = 3                 // samples over threshold within window

    // = Raise detection heuristic
    private let raisePitchThresholdDeg: Double = 50    // pitch needed to consider as raised
    private let lowerPitchThresholdDeg: Double = 40    // lower threshold to drop raised state
    private let rollLimitNotRaisedDeg: Double = 45     // stricter roll limit before first raise
    private let rollLimitRaisedDeg: Double = 65        // more lenient roll once raised
    private let postureDecisionSamples: Int = 3        // consecutive samples to confirm change
    private var raiseStreak = 0
    private var lowerStreak = 0

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
            let pitchDeg = motion.attitude.pitch * 180 / .pi
            let rollDeg  = motion.attitude.roll  * 180 / .pi

            if self.isPhoneRaised {
                // When already raised, allow more roll and require a deeper drop in pitch
                let stillRaised = (pitchDeg >= self.lowerPitchThresholdDeg) && (abs(rollDeg) <= self.rollLimitRaisedDeg)
                if stillRaised {
                    self.raiseStreak = min(self.raiseStreak + 1, self.postureDecisionSamples)
                    self.lowerStreak = 0
                } else {
                    self.lowerStreak += 1
                    self.raiseStreak = 0
                }

                if self.lowerStreak >= self.postureDecisionSamples {
                    self.isPhoneRaised = false
                    self.lowerStreak = 0
                    self.delegates.forEach { $0.didLower() }
                }
            } else {
                // Before being raised, use stricter roll limit and higher pitch threshold
                let meetsRaise = (pitchDeg >= self.raisePitchThresholdDeg) && (abs(rollDeg) <= self.rollLimitNotRaisedDeg)
                if meetsRaise {
                    self.raiseStreak += 1
                    self.lowerStreak = 0
                } else {
                    self.lowerStreak = min(self.lowerStreak + 1, self.postureDecisionSamples)
                    self.raiseStreak = 0
                }

                if self.raiseStreak >= self.postureDecisionSamples {
                    self.isPhoneRaised = true
                    self.raiseStreak = 0
                    self.delegates.forEach { $0.didRaise() }
                }
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

