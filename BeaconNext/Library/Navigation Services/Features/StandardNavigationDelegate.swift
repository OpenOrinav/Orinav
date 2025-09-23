import SwiftUI
import CoreLocation

class StandardNavigationDelegate: ObservableObject {
    @Published var correctHeading: CLLocationDirection?
    
    let globalUIState: BeaconGlobalUIState
    let locationDelegate: StandardLocationDelegate
    
    var navigationStartAt = Date()
    let NO_SPEECH_IN_FIRST = 7.0   // seconds after starting navigation
    
    // INTERSECTION PROCESSING
    // State
    var atIntersection = false
    var minDistanceDuringIntersection: Double? = nil
    var lastIntersectionUpdateAt = Date()
    
    // Tunables (meters)
    let ENTER_THRESH: Double = 12.0   // when approaching a non-straight step
    let EXIT_DELTA: Double = 10.0     // leave after distance increases ≥ this from the min
    let EXIT_FAR: Double = 25.0       // or if type flips straight and we're clearly away
    // END INTERSECTION PROCESSING
    
    init(globalUIState: BeaconGlobalUIState, locationDelegate: StandardLocationDelegate) {
        self.globalUIState = globalUIState
        self.locationDelegate = locationDelegate
    }
}

extension StandardNavigationDelegate: DeviceMotionDelegate {
    // = Speak navigation information when user shakes device
    func didShake() {
        if BeaconExploreView.inExplore { return } // Don't conflict with Explore mode shake
        if globalUIState.routeInNavigation == nil { return }
        guard let data = globalUIState.navigationStatus else { return }
        ShakeInformFeature.shared.speak(data, angleDiff: ((locationDelegate.currentHeading ?? 0) - (correctHeading ?? 0) + 540).truncatingRemainder(dividingBy: 360) - 180)
    }
}

extension StandardNavigationDelegate: BeaconNavigationProviderDelegate {
    // = Record time of starting navigation
    func didStartNavigation() {
        navigationStartAt = Date()
    }
    
    // = End navigation state when UI end button is activated
    func didEndNavigation() {
        // Reset state
        AngleDeviationFeature.shared.reset()
        ApproachingNextStepFeature.shared.reset()
        
        DispatchQueue.main.async {
            self.globalUIState.currentPage = nil
            BeaconTTSService.shared.speak(String(localized: "Navigation ended"), type: .navigation)
        }
    }
    
    // = Speak when the user deviates significantly from a correct heading
    func didReceiveRoadAngle(_ angle: CLLocationDirection) {
        DispatchQueue.main.async {
            self.correctHeading = angle
        }
        guard let heading = locationDelegate.currentHeading else { return }
        if Date().timeIntervalSince(navigationStartAt) >= NO_SPEECH_IN_FIRST {
            AngleDeviationFeature.shared.speak(from: angle, currentHeading: heading)
        }
        AngleDeviationFeature.shared.playHaptics(from: angle, currentHeading: heading)
    }
    
    // = Publish navigation data
    // = Determine if the user is at an intersection
    func didReceiveNavigationStatus(_ status: any BeaconNavigationStatus) {
        DispatchQueue.main.async {
            self.globalUIState.navigationStatus = status
        }
        // Don't speak in the first few seconds to avoid overriding initial prompts
        if Date().timeIntervalSince(navigationStartAt) < NO_SPEECH_IN_FIRST {
            ApproachingNextStepFeature.shared.notify(status)
        }
    
        // == Are we at an intersection?
        let d = Double(status.bDistanceToNextSegmentMeters)
        let isTurn = status.bTurnType != .straight && status.bTurnType != .stop && status.bTurnType != .unnavigable
        
        if !atIntersection {
            // ENTER: close to the upcoming turn
            if isTurn && d <= ENTER_THRESH {
                atIntersection = true
                minDistanceDuringIntersection = d
                lastIntersectionUpdateAt = Date()
                DispatchQueue.main.async {
                    self.globalUIState.atIntersection = true
                }
            }
        } else {
            // While AT: track the closest approach
            if let m = minDistanceDuringIntersection {
                minDistanceDuringIntersection = min(m, d)
            } else {
                minDistanceDuringIntersection = d
            }
            
            let minD = minDistanceDuringIntersection ?? d
            
            // EXIT condition A: we've moved away from the closest point by ≥ EXIT_DELTA
            let movedAway = (d - minD) >= EXIT_DELTA
            
            // EXIT condition B: provider flipped to straight AND we're clearly beyond the junction
            let typeMovedOn = (!isTurn && d >= EXIT_FAR)
            
            // Timeout
            let timedOut = Date().timeIntervalSince(lastIntersectionUpdateAt) > 30
            
            if movedAway || typeMovedOn || timedOut {
                atIntersection = false
                minDistanceDuringIntersection = nil
                DispatchQueue.main.async {
                    self.globalUIState.atIntersection = false
                }
            }
        }
    }
}
