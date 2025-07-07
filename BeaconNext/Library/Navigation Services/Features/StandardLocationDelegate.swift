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
        DispatchQueue.main.async {
            self.currentLocation = location
            self.speakAddress()
        }
    }
    
    func didUpdateHeading(_ heading: CLLocationDirection) {
        DispatchQueue.main.async {
            self.currentHeading = heading
            self.speakFacingDirection()
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
                BeaconTTSService.shared.speak([
                    (text: "You are currently at", language: "en-US"),
                    (text: currentAddress, language: "zh-CN")
                ], type: .currentLocation)
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
            BeaconTTSService.shared.speak([
                (text: dir, language: "en-US")
            ], type: .currentHeading)
        }
        lastSpokenDirection = dir
    }
    
    // = Speak location upon shaking (if not in navigation)
    func didShake() {
        if globalUIState.routeInNavigation == nil {
            self.speakAddress(force: true)
        }
    }
    
    func name(forDegrees degrees: Double) -> String {
        let directions = ["North", "Northeast", "East", "Southeast", "South", "Southwest", "West", "Northwest"]
        let index = Int((degrees + 22.5) / 45) & 7
        return directions[index]
    }
}
