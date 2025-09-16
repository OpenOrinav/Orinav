import QMapKit
import TencentNavKit
import CoreLocation

extension TencentLBSLocation: BeaconLocation {
    var bCoordinate: CLLocationCoordinate2D {
        location.coordinate
    }
    
    var bName: String? {
        name
    }
}

class QMapLocationProvider: NSObject, ObservableObject, BeaconLocationProvider, TencentLBSLocationManagerDelegate {
    var delegate: BeaconLocationProviderDelegate?
    var currentLocation: BeaconLocation?
    var currentHeading: CLLocationDirection?
    
    private var locationManager: TencentLBSLocationManager
    
    
    override init() {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "TencentAPIKey") as? String else {
            fatalError("Missing TencentAPIKey in Info.plist")
        }
        
        self.locationManager = TencentLBSLocationManager()
        self.locationManager.apiKey = apiKey
        self.locationManager.pausesLocationUpdatesAutomatically = false
        self.locationManager.requestLevel = .name
        
        super.init()
        self.locationManager.delegate = self
        self.locationManager.headingFilter = 5
        self.locationManager.startUpdatingHeading()
        self.locationManager.startUpdatingLocation()
    }
    
    func requestPermissions() {
        let cl = CLLocationManager()
        if cl.authorizationStatus == .notDetermined {
            self.locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func tencentLBSLocationManager(
        _ manager: TencentLBSLocationManager,
        didUpdate location: TencentLBSLocation
    ) {
        currentLocation = location // FIXME: For some reason I am entirely confused over, locations no longer update since Sep 10, 2025. I did not change the code. This also breaks search, which relies on a central location. It may be related to updating to iOS 26.
        currentHeading = location.direction
        if let delegate = delegate {
            delegate.didUpdateLocation(location)
            delegate.didUpdateHeading(location.direction)
        }
    }
    
    func tencentLBSLocationManager(
        _ manager: TencentLBSLocationManager,
        didFailWithError error: any Error
    ) {
        print(error)
    }
}
