import CoreLocation

protocol BeaconLocationProvider {
    var delegate: BeaconLocationProviderDelegate? { get set }
    
    var currentLocation: BeaconLocation? { get }
    var currentHeading: CLLocationDirection? { get }
}
