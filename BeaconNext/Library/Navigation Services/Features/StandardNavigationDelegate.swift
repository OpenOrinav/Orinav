import SwiftUI
import CoreLocation

class StandardNavigationDelegate: BeaconNavigationProviderDelegate, DeviceMotionDelegate, ObservableObject {
    @Published var correctHeading: CLLocationDirection?
    
    let globalUIState: BeaconGlobalUIState
    let locationDelegate: StandardLocationDelegate
    
    init(globalUIState: BeaconGlobalUIState, locationDelegate: StandardLocationDelegate) {
        self.globalUIState = globalUIState
        self.locationDelegate = locationDelegate
    }
    
    // = Allow ending navigation UI state AFTER ending navigation
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
        AngleDeviationFeature.shared.speak(from: angle, currentHeading: heading)
        AngleDeviationFeature.shared.playHaptics(from: angle, currentHeading: heading)
    }
    
    // = Publish navigation data
    func didReceiveNavigationStatus(_ status: any BeaconNavigationStatus) {
        DispatchQueue.main.async {
            self.globalUIState.navigationStatus = status
        }
        ApproachingNextStepFeature.shared.notify(status)
    }
    
    // = Speak navigation information when user shakes device
    func didShake() {
        if BeaconExploreView.inExplore { return } // Don't conflict with Explore mode shake
        if globalUIState.routeInNavigation == nil { return }
        guard let data = globalUIState.navigationStatus else { return }
        ShakeInformFeature.shared.speak(data, angleDiff: ((locationDelegate.currentHeading ?? 0) - (correctHeading ?? 0) + 540).truncatingRemainder(dividingBy: 360) - 180)
    }
}
