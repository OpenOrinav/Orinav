import CoreLocation
import SwiftUI
import UIKit
import CoreHaptics

class AngleDeviationFeature {
    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?
    
    static let shared = AngleDeviationFeature()

    init() { prepareEngine() }
    
    // Language
    var lastDirection: String? = nil
    var lastFacingAngle: CLLocationDirection? = nil
    var hasSpokenRightDirection: Bool = false
    
    func reset() {
        lastDirection = nil
        lastFacingAngle = nil
        hasSpokenRightDirection = false
    }
    
    func speak(from correctHeading: CLLocationDirection, currentHeading: CLLocationDirection) {
        let signedDiff = (currentHeading - correctHeading + 540).truncatingRemainder(dividingBy: 360) - 180
        
        if abs(signedDiff) >= 20 {
            let currentDirection = oClockRepresentation(from: signedDiff)
            
            if currentDirection != lastDirection || (lastFacingAngle != nil && abs(currentHeading - lastFacingAngle!) > 5) {
                BeaconTTSService.shared.speak("Turn \(currentDirection)")
                lastDirection = currentDirection
                lastFacingAngle = currentHeading
            }
            hasSpokenRightDirection = false
        } else {
            lastDirection = nil
            lastFacingAngle = nil
            
            if !hasSpokenRightDirection {
                SoundEffectsManager.shared.playSuccess()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    BeaconTTSService.shared.speak("Aligned")
                }
                hasSpokenRightDirection = true
            }
        }
    }
    
    func oClockRepresentation(from angle: Double) -> String {
        let normalized = angle >= 0 ? angle : 360 + angle
        let adjusted = (normalized + 15).truncatingRemainder(dividingBy: 360)
        let hour = Int(adjusted / 30)
        let hourLabels = [12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
        return "\(hourLabels[hour]) o'clock"
    }

    
    // Haptics
    private func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptic engine failed: \(error)")
        }
    }

    func playHaptics(from angle: CLLocationDirection, currentHeading: CLLocationDirection) {
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
