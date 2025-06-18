import CoreLocation
import Combine

class HeadingManager: NSObject, CLLocationManagerDelegate {
    static let shared = HeadingManager()
    
    private let locationManager = CLLocationManager()
    @Published var currentHeading: CLHeading?

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.headingFilter = 5
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingHeading()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        currentHeading = newHeading
    }

    func getValidHeading() -> CLLocationDirection? {
        guard let heading = currentHeading else { return nil }
        return heading.trueHeading >= 0 ? heading.trueHeading : heading.magneticHeading
    }
    
}
