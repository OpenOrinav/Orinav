import Foundation
import CoreLocation
import MapboxSearch

class MapboxLocationProvider: NSObject {
    var delegate: BeaconLocationProviderDelegate?
    private let locationManager = CLLocationManager()

    private let accessToken: String
    
    override init() {
        guard let accessToken = Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String else {
            fatalError("Missing MBXAccessToken in Info.plist")
        }
        self.accessToken = accessToken
        
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.headingFilter = 5
        locationManager.requestWhenInUseAuthorization()
        startUpdating()
    }

    func startUpdating() {
        guard CLLocationManager.locationServicesEnabled() else { return }
        locationManager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }
    }
    func stopUpdating() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
}

// MARK: - CLLocationManagerDelegate
extension MapboxLocationProvider: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            startUpdating()
        default:
            stopUpdating()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        let placeAutocomplete = PlaceAutocomplete(accessToken: accessToken)
        placeAutocomplete.suggestions(for: latest.coordinate) { result in
            switch result {
            case .success(let suggestions):
                self.delegate?.didUpdateLocation(MapboxWrappedBeaconLocation(suggestions[0]))

            case .failure(let error):
                print("MapboxLocationProvider error (Mapbox): \(error)")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        delegate?.didUpdateHeading(newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("MapboxLocationProvider error: \(error.localizedDescription)")
    }
}

class MapboxWrappedBeaconLocation: BeaconLocation {
    private let mapboxPOI: PlaceAutocomplete.Suggestion
    
    init(_ mapboxPOI: PlaceAutocomplete.Suggestion) {
        self.mapboxPOI = mapboxPOI
    }
    
    var bCoordinate: CLLocationCoordinate2D {
        return mapboxPOI.coordinate!
    }
    
    var bName: String? {
        return mapboxPOI.name
    }
}
