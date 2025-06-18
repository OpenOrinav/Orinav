import CoreLocation

protocol BeaconLocation {
    var bLocation: CLLocationCoordinate2D { get }
    var bName: String? { get }
}
