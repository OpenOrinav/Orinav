import Foundation
import CoreLocation
import CoreMotion

class StandardLocationDelegate: ObservableObject, BeaconLocationProviderDelegate, DeviceMotionDelegate {
    @Published var currentLocation: BeaconLocation?
    @Published var currentHeading: CLLocationDirection?
    
    let globalUIState: BeaconGlobalUIState
    
    init(globalUIState: BeaconGlobalUIState) {
        self.globalUIState = globalUIState
    }
    
    func didUpdateLocation(_ location: BeaconLocation) {
        TraceLoggingFeature.shared.log(location.bCoordinate)
        
        DispatchQueue.main.async {
            self.currentLocation = location
            if SettingsManager.shared.sayLocation {
                self.speakAddress()
            }
        }
    }
    
    func didUpdateHeading(_ heading: CLLocationDirection) {
        DispatchQueue.main.async {
            self.currentHeading = heading
            if SettingsManager.shared.sayDirection {
                self.speakFacingDirection()
            }
        }
    }
    
    // MARK: - Relevant features
    private var lastSpokenAddress: String?
    private var lastSpokenDirection: String?
    private var isFirstWord = true
    
    // = Speak the user's location whenever it changes or when the user shakes the device
    func speakAddress(force: Bool = false) {
        guard let currentAddress = currentLocation?.bName else { return }
        
        if force || currentAddress != lastSpokenAddress {
            DispatchQueue.main.async {
                BeaconTTSService.shared.speak(String(localized: "At \(currentAddress)"), type: .currentLocation)
            }
            lastSpokenAddress = currentAddress
            isFirstWord = false
        }
    }
    
    // = Speak the user's facing direction whenever it changes
    func speakFacingDirection() {
        guard let degrees = currentHeading else { return }
        let dir = name(forDegrees: degrees)
        
        if dir == lastSpokenDirection || isFirstWord || globalUIState.routeInNavigation != nil {
            return
        }
        DispatchQueue.main.async {
            BeaconTTSService.shared.speak(dir, type: .currentHeading)
        }
        lastSpokenDirection = dir
    }
    
    // = Speak location upon shaking (if not in navigation)
    func didShake() {
        if BeaconExploreView.inExplore { return } // Don't conflict with Explore mode shake
        if globalUIState.routeInNavigation == nil {
            self.speakAddress(force: true)
        }
    }
    
    func name(forDegrees degrees: Double) -> String {
        let directions = [
            String(localized: "North"),
            String(localized: "Northeast"),
            String(localized: "East"),
            String(localized: "Southeast"),
            String(localized: "South"),
            String(localized: "Southwest"),
            String(localized: "West"),
            String(localized: "Northwest")
        ]
        let index = Int((degrees + 22.5) / 45) & 7
        return directions[index]
    }
}
