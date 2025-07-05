import Foundation
import SwiftUI
import UIKit
import CoreHaptics

class NavigationHapticsManager {
    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?
    
    static let shared = NavigationHapticsManager()

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
