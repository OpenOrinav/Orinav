import SwiftUI
import CoreLocation

class StandardNavigationDelegate: BeaconNavigationProviderDelegate, ObservableObject {
    @Published var status: BeaconNavigationStatus?
    
    let globalUIState: BeaconGlobalUIState
    let locationDelegate: StandardLocationDelegate
    
    init(globalUIState: BeaconGlobalUIState, locationDelegate: StandardLocationDelegate) {
        self.globalUIState = globalUIState
        self.locationDelegate = locationDelegate
    }
    
    // = Allow ending navigation
    func onEndNavigation() {
        DispatchQueue.main.async {
            self.globalUIState.currentPage = nil
            BeaconTTSService.shared.speak("Navigation ended")
        }
    }
    
    // = Speak when the user deviates significantly from a correct heading
    var lastDirection: String? = nil
    var lastFacingAngle: CLLocationDirection? = nil
    var hasSpokenRightDirection: Bool = false
    
    func speakAngularDeviation(from correctHeading: CLLocationDirection) {
        guard let currentHeading = locationDelegate.currentHeading else { return }
        
        let signedDiff = (currentHeading - correctHeading + 540).truncatingRemainder(dividingBy: 360) - 180
        
        if abs(signedDiff) >= 20 {
            let currentDirection = oClockRepresentation(from: signedDiff)
            
            if currentDirection != lastDirection || (lastFacingAngle != nil && abs(currentHeading - lastFacingAngle!) > 5) {
                BeaconTTSService.shared.speak("Head \(currentDirection)")
                lastDirection = currentDirection
                lastFacingAngle = currentHeading
            }
            hasSpokenRightDirection = false
        } else {
            lastDirection = nil
            lastFacingAngle = nil
            
            if !hasSpokenRightDirection {
                BeaconTTSService.shared.speak("You are at the right direction")
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
    
    func onReceiveRoadAngle(_ angle: CLLocationDirection) {
        speakAngularDeviation(from: angle)
    }
    
    // = Publish navigation data
    func onReceiveNavigationStatus(_ status: any BeaconNavigationStatus) {
        DispatchQueue.main.async {
            self.status = status
        }
    }
}
