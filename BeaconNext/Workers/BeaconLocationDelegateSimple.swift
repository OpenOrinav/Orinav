import AMapLocationKit
import CoreLocation

class BeaconLocationDelegateSimple: NSObject, ObservableObject, AMapLocationManagerDelegate, CLLocationManagerDelegate {
    @Published var lastLocation: CLLocation?
    @Published var lastAddress: AMapLocationReGeocode?
    
    private var locationManager: AMapLocationManager
    private var headingManager: CLLocationManager
    
    override init() {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "AmapAPIKey") as? String else {
            fatalError("Missing AmapAPIKey in Info.plist")
        }
        AMapServices.shared().apiKey = apiKey
        
        // For development only
        AMapLocationManager.updatePrivacyShow(.didShow, privacyInfo: .didContain)
        AMapLocationManager.updatePrivacyAgree(.didAgree)
        
        self.locationManager = AMapLocationManager()
        self.headingManager = CLLocationManager()
        super.init()

        self.locationManager.delegate = self
        self.locationManager.locatingWithReGeocode = true
        self.locationManager.startUpdatingLocation()


        self.headingManager.delegate = self
        self.headingManager.headingFilter = 20
        self.headingManager.startUpdatingHeading()
        
        // Speak welcome message
        DispatchQueue.main.async {
            BeaconTTSService.shared.speak([
                (text: "Welcome to Beacon.", language: "en-US")
            ])
        }
    }
    
    
    // MARK: - Location delegate
    func amapLocationManager(_ manager: AMapLocationManager!, didUpdate location: CLLocation!, reGeocode: AMapLocationReGeocode!) {
        DispatchQueue.main.async {
            self.lastLocation = location
            if let reGeocode = reGeocode {
                self.speakAddress()
                self.lastAddress = reGeocode
            }
        }
    }
    
    // MARK: - Heading delegate
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Map heading (0–360) to eight compass points
        let degrees = newHeading.magneticHeading
        let directions = ["North", "Northeast", "East", "Southeast", "South", "Southwest", "West", "Northwest"]
        let index = Int((degrees + 22.5) / 45) & 7
        let dir = directions[index]
        DispatchQueue.main.async {
            self.speakFacingDirection(direction: dir)
        }
    }
    
    // MARK: - Speaking
    private var lastSpokenAddress: String?
    private var lastSpokenDirection: String?
    
    func speakAddress() {
        if lastAddress?.poiName != lastSpokenAddress {
            guard let lastAddress = lastAddress else { return }
            BeaconTTSService.shared.speak([
                (text: "You are currently at", language: "en-US"),
                (text: lastAddress.poiName ?? "unknown location", language: "zh-CN")
            ])
            lastSpokenAddress = lastAddress.poiName
        }
    }
    
    // MARK: - Heading Delegate
    func speakFacingDirection(direction: String) {
        if direction == lastSpokenDirection {
            return
        }
        BeaconTTSService.shared.speak([
            (text: direction, language: "en-US")
        ])
        lastSpokenDirection = direction
    }
}
