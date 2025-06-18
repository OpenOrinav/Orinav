import QMapKit
import TencentNavKit
import CoreLocation

extension TencentLBSLocation: BeaconLocation {
    var bLocation: CLLocationCoordinate2D {
        location.coordinate
    }
    
    var bName: String? {
        name
    }
}

class QMapLocationProvider: NSObject, ObservableObject, BeaconLocationProvider, TencentLBSLocationManagerDelegate {
    var delegate: BeaconLocationProviderDelegate?
    
    private var locationManager: TencentLBSLocationManager
    
    override init() {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "TencentAPIKey") as? String else {
            fatalError("Missing TencentAPIKey in Info.plist")
        }
        
        self.locationManager = TencentLBSLocationManager()
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
        if let delegate = delegate {
            delegate.didUpdateLocation(location)
            delegate.didUpdateHeading(location.direction)
        }
    }
}
