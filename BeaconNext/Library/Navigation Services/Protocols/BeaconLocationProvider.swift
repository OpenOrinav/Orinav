import CoreLocation

protocol BeaconLocationProvider {
    var delegate: BeaconLocationProviderDelegate? { get set }
    
    var currentLocation: BeaconLocation? { get }
    var currentHeading: CLLocationDirection? { get }
    
    func requestPermissions()
    func requestAlwaysPermissions()
    func setPauseLocation(_ pause: Bool)
}
