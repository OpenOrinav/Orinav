import Foundation
import SwiftUI
import UIKit
import CoreHaptics

class UIKitHapticsManager {
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

class CoreHapticsManager {
    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?
    
    static let shared = CoreHapticsManager()

    init() { prepareEngine() }

    private func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptic engine failed: \(error)")
        }
    }
    
    @ObservedObject var LocationDelegate = StandardLocationDelegate.shared

    func playPattern(for angle: Double, currentHeading: Double) {
        stop()
        
        let signedDiff = (currentHeading - angle + 540).truncatingRemainder(dividingBy: 360) - 180
        let absAngle = abs(signedDiff)

        let interval: TimeInterval

        if absAngle >= 50 {
            interval = 0.2
        } else {
            let normalized = absAngle / 50.0
            interval = 1.5 - normalized * (1.5 - 0.2)
        }

        var events: [CHHapticEvent] = []
        let totalDuration: TimeInterval = 2.0
        var currentTime: TimeInterval = 0

        while currentTime < totalDuration {
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                ],
                relativeTime: currentTime
            )
            events.append(event)
            currentTime += interval
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            player = try engine?.makeAdvancedPlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play haptic pattern: \(error)")
        }
    }

    func stop() {
        try? player?.stop(atTime: 0)
        player = nil
    }
}
