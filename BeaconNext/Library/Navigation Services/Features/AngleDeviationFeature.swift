import CoreLocation
import SwiftUI
import UIKit
import CoreHaptics

final class AngleDeviationFeature {
    private var lastSpeakTime = Date.distantPast
    static let correctHeadingLimit: Double = 20
    
    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?
    
    // Reactivate haptics after backgrounding
    private var didBecomeActiveObserver: NSObjectProtocol?
    private var willResignActiveObserver: NSObjectProtocol?
    
    static let shared = AngleDeviationFeature()

    private init() { prepareEngine() }
    
    // Language
    var lastDirection: Int? = nil
    var lastFacingAngle: CLLocationDirection? = nil
    var hasSpokenRightDirection: Bool = false
    
    func reset() {
        lastDirection = nil
        lastFacingAngle = nil
        hasSpokenRightDirection = false
    }
    
    func speak(from correctHeading: CLLocationDirection, currentHeading: CLLocationDirection) {
        let signedDiff = (currentHeading - correctHeading + 540).truncatingRemainder(dividingBy: 360) - 180
        let now = Date()
        if now.timeIntervalSince(lastSpeakTime) < 0.5 {
            return
        }
        lastSpeakTime = now
        
        if abs(signedDiff) >= AngleDeviationFeature.correctHeadingLimit {
            let currentDirection = AngleDeviationFeature.oClockRepresentation(from: signedDiff)
            
            if currentDirection != lastDirection || (lastFacingAngle != nil && abs(currentHeading - lastFacingAngle!) > 5) {
                DispatchQueue.main.async {
                    BeaconTTSService.shared.speak(String(localized: "Turn \(String(currentDirection)) o' clock"), type: .angleDeviation)
                }
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
                    BeaconTTSService.shared.speak(String(localized: "Aligned"), type: .angleDeviation)
                }
                hasSpokenRightDirection = true
            }
        }
    }
    
    static func oClockRepresentation(from angle: Double) -> Int {
        let normalized = angle >= 0 ? angle : 360 + angle
        let adjusted = (normalized + 15).truncatingRemainder(dividingBy: 360)
        let hour = Int(adjusted / 30)
        let hourLabels = [12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
        return hourLabels[hour]
    }

    
    // Haptics
    private func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            engine?.stoppedHandler = { [weak self] reason in
                // Clear player upon backgrounding
                self?.player = nil
            }
            engine?.resetHandler = { [weak self] in
                self?.player = nil
                try? self?.engine?.start()
            }
            try engine?.start()
        } catch {
            print("Haptic engine failed: \(error)")
        }

        // Restart engine when app becomes active again
        if didBecomeActiveObserver == nil {
            didBecomeActiveObserver = NotificationCenter.default.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
                do { try self.engine?.start() } catch { }
            }
        }
        if willResignActiveObserver == nil {
            willResignActiveObserver = NotificationCenter.default.addObserver(
                forName: UIApplication.willResignActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                // Stop current player cleanly when app resigns active
                self?.stop()
            }
        }
    }

    private func ensureEngineRunning() -> Bool {
        guard UIApplication.shared.applicationState == .active else { return false }
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return false }
        if engine == nil { prepareEngine() }
        do { try engine?.start() } catch { print("Failed to start haptics engine: \(error)") }
        return engine != nil
    }

    func playHaptics(from angle: CLLocationDirection, currentHeading: CLLocationDirection) {
        if BeaconExploreView.inExplore { return } // Don't interfere with Explore haptics
        
        guard ensureEngineRunning() else { return }

        stop()

        let signedDiff = (currentHeading - angle + 540).truncatingRemainder(dividingBy: 360) - 180
        let absAngle = abs(signedDiff)

        // Determine interval, intensity, and sharpness based on deviation
        let interval: TimeInterval
        let intensity: Float
        let sharpness: Float

        if absAngle <= AngleDeviationFeature.correctHeadingLimit {
            // Light feedback every second when within acceptable limit
            interval = 1.0
            intensity = 0.5
            sharpness = 0.3
        } else {
            // Increase feedback frequency and strength with larger deviation
            let normalized = min(absAngle, 180.0) / 180.0
            interval = 0.8 - normalized * 0.7   // from 2s down to 0.1s
            intensity = Float(0.5 + normalized * 0.5)  // from 0.5 up to 1.0
            sharpness = Float(0.5 + normalized * 0.5)  // from 0.5 up to 1.0
        }

        // Build transient haptic events for a 2-second window
        var events: [CHHapticEvent] = []
        let totalDuration: TimeInterval = 2.0
        var currentTime: TimeInterval = 0

        while currentTime < totalDuration {
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
                ],
                relativeTime: currentTime
            )
            events.append(event)
            currentTime += interval
        }

        // Play the pattern
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
    
    deinit {
        if let o = didBecomeActiveObserver { NotificationCenter.default.removeObserver(o) }
        if let o = willResignActiveObserver { NotificationCenter.default.removeObserver(o) }
    }
}
