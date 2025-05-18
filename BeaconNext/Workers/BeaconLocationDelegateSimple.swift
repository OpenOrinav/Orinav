import QMapKit
import TencentNavKit
import CoreLocation

class BeaconLocationDelegateSimple: NSObject, ObservableObject, TencentLBSLocationManagerDelegate {
    @Published var lastLocation: CLLocation?
    @Published var lastAddress: String?
    
    private var locationManager: TencentLBSLocationManager
    
    override init() {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "TencentAPIKey") as? String else {
            fatalError("Missing TencentAPIKey in Info.plist")
        }
        QMapServices.shared().setPrivacyAgreement(true)
        TNKNavServices.shared().setPrivacyAgreement(true)
        self.locationManager = TencentLBSLocationManager()
        
        QMapServices.shared().apiKey = apiKey
        TNKNavServices.shared().key = apiKey
        self.locationManager.apiKey = apiKey
        self.locationManager.pausesLocationUpdatesAutomatically = false
        self.locationManager.requestLevel = .name
        
        let cl = CLLocationManager()
        if (cl.authorizationStatus == .notDetermined) {
            self.locationManager.requestWhenInUseAuthorization()
        }
        
        super.init()
        self.locationManager.delegate = self
        self.locationManager.headingFilter = 10
        self.locationManager.startUpdatingHeading()
        self.locationManager.startUpdatingLocation()
    }
    
    func tencentLBSLocationManager(
        _ manager: TencentLBSLocationManager,
        didUpdate location: TencentLBSLocation
    ) {
        DispatchQueue.main.async {
            self.lastLocation = location.location
            self.lastAddress = location.name
            self.speakAddress()
            
            let degrees = location.direction
            let directions = ["North", "Northeast", "East", "Southeast", "South", "Southwest", "West", "Northwest"]
            let index = Int((degrees + 22.5) / 45) & 7
            let dir = directions[index]
            
            // FIXME This isn't triggering as much as I would like
            self.speakFacingDirection(direction: dir)
        }
    }
    
    
    // MARK: - Speaking
    private var lastSpokenAddress: String?
    private var lastSpokenDirection: String?
    private var isFirstWord = true // Arbitrarily delay speaking the direction
    
    func speakAddress() {
        if lastAddress != lastSpokenAddress {
            guard let lastAddress = lastAddress else { return }
            BeaconTTSService.shared.speak([
                (text: "You are currently at", language: "en-US"),
                (text: lastAddress, language: "zh-CN")
            ])
            lastSpokenAddress = lastAddress
            isFirstWord = false
        }
    }
    
    // MARK: - Heading Delegate
    func speakFacingDirection(direction: String) {
        if direction == lastSpokenDirection || isFirstWord {
            return
        }
        BeaconTTSService.shared.speak([
            (text: direction, language: "en-US")
        ])
        lastSpokenDirection = direction
    }
}
