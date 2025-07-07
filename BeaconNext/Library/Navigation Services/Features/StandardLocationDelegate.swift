import Foundation
import CoreLocation
import CoreMotion

class StandardLocationDelegate: ObservableObject, BeaconLocationProviderDelegate {
    @Published var currentLocation: BeaconLocation?
    @Published var currentHeading: CLLocationDirection?
    
    let globalUIState: BeaconGlobalUIState
    
    init(globalUIState: BeaconGlobalUIState) {
        self.globalUIState = globalUIState
        startShakeDetection()
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
    
    func name(forDegrees degrees: Double) -> String {
        let directions = ["North", "Northeast", "East", "Southeast", "South", "Southwest", "West", "Northwest"]
        let index = Int((degrees + 22.5) / 45) & 7
        return directions[index]
    }
    
    
    private var motionManager = CMMotionManager()
    private var lastShakeTime: Date? = nil
    private var lastAccel: CMAcceleration?
    
    private func startShakeDetection() {
        guard motionManager.isAccelerometerAvailable else { return }
        
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { data, error in
            guard let data = data else { return }
            
            let accel = data.acceleration
            
            if let last = self.lastAccel {
                let deltaX = abs(accel.x - last.x)
                let deltaY = abs(accel.y - last.y)
                let deltaZ = abs(accel.z - last.z)
                
                let shakeThreshold = 0.6 // Sensitivity
                let cooldown: TimeInterval = 3.0
                
                if deltaX > shakeThreshold || deltaY > shakeThreshold || deltaZ > shakeThreshold {
                    let now = Date()
                    if let last = self.lastShakeTime, now.timeIntervalSince(last) < cooldown {
                        return
                    }
                    
                    self.lastShakeTime = now
                    self.speakAddress(force: true)
                }
            }
            
            self.lastAccel = accel
        }
    }
}
