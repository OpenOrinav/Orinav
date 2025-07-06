import SwiftUI
import CoreLocation

class StandardNavigationDelegate: BeaconNavigationProviderDelegate, ObservableObject {
    @Published var correctHeading: CLLocationDirection?
    
    let globalUIState: BeaconGlobalUIState
    let locationDelegate: StandardLocationDelegate
    
    init(globalUIState: BeaconGlobalUIState, locationDelegate: StandardLocationDelegate) {
        self.globalUIState = globalUIState
        self.locationDelegate = locationDelegate
    }
    
    // = Allow ending navigation
    func shouldEndNavigation() {
        // Reset state
        AngleDeviationFeature.shared.reset()
        
        DispatchQueue.main.async {
            self.globalUIState.currentPage = nil
            BeaconTTSService.shared.speak("Navigation ended")
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
    }
}
