import AMapLocationKit
import CoreLocation

class BeaconLocationDelegateSimple: NSObject, ObservableObject, AMapLocationManagerDelegate {
    @Published var lastLocation: CLLocation?
    @Published var lastAddress: AMapLocationReGeocode?
    private var locationManager: AMapLocationManager
    
    override init() {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "AmapAPIKey") as? String else {
            fatalError("Missing AmapAPIKey in Info.plist")
        }
        AMapServices.shared().apiKey = apiKey
        
        // For development only
        AMapLocationManager.updatePrivacyShow(.didShow, privacyInfo: .didContain)
        AMapLocationManager.updatePrivacyAgree(.didAgree)

        self.locationManager = AMapLocationManager()
        super.init()
        self.locationManager.delegate = self
        self.locationManager.locatingWithReGeocode = true
        self.locationManager.startUpdatingLocation()
    }
    
    func amapLocationManager(_ manager: AMapLocationManager!, didUpdate location: CLLocation!, reGeocode: AMapLocationReGeocode!) {
        DispatchQueue.main.async {
            self.lastLocation = location
            if let reGeocode = reGeocode {
                self.lastAddress = reGeocode
            }
        }
    }
}
