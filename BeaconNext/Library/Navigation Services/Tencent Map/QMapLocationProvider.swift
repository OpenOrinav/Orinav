import QMapKit
import TencentNavKit
import CoreLocation

class QMapLocationProvider: NSObject, ObservableObject, BeaconLocationProvider {
    var delegate: BeaconLocationProviderDelegate?
    var currentLocation: BeaconLocation?
    var currentHeading: CLLocationDirection?
    var permissionStatus: CLAuthorizationStatus
    
    let cl = CLLocationManager()
    
    private var locationManager: TencentLBSLocationManager
    
    
    override init() {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "TencentAPIKey") as? String else {
            fatalError("Missing TencentAPIKey in Info.plist")
        }
        
        self.locationManager = TencentLBSLocationManager()
        self.locationManager.apiKey = apiKey
        self.locationManager.pausesLocationUpdatesAutomatically = false
        self.locationManager.requestLevel = .adminName
        self.permissionStatus = cl.authorizationStatus
        
        super.init()
        cl.delegate = self
        self.locationManager.delegate = self
        self.locationManager.headingFilter = 5
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.startUpdatingHeading()
        self.locationManager.startUpdatingLocation()
    }
    
    func requestPermissions() {
        if cl.authorizationStatus == .notDetermined {
            self.locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func requestAlwaysPermissions() {
        self.locationManager.requestAlwaysAuthorization()
    }
    
    func setPauseLocation(_ pause: Bool) {
        self.locationManager.pausesLocationUpdatesAutomatically = pause
    }
}

extension QMapLocationProvider: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        delegate?.didUpdateAuthorizationStatus(status)
    }
}

extension QMapLocationProvider: TencentLBSLocationManagerDelegate {
    func tencentLBSLocationManager(
        _ manager: TencentLBSLocationManager,
        didUpdate location: TencentLBSLocation
    ) {
        currentLocation = location
        currentHeading = location.direction
        if let delegate = delegate {
            delegate.didUpdateLocation(location)
            delegate.didUpdateHeading(location.direction)
        }
    }
    
    func tencentLBSLocationManager(
        _ manager: TencentLBSLocationManager,
        didUpdate newHeading: CLHeading
    ) {
        if let delegate = delegate {
            delegate.didUpdateHeading(newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading)
        }
    }
    
    func tencentLBSLocationManager(
        _ manager: TencentLBSLocationManager,
        didFailWithError error: any Error
    ) {
        print(error)
    }
}

extension TencentLBSLocation: BeaconLocation {
    var bCoordinate: CLLocationCoordinate2D {
        location.coordinate
    }
    
    var bName: String? {
        name
    }
    
    var bCity: String? {
        city
    }
}
