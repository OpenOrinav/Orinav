import CoreLocation

protocol BeaconLocation {
    var bLocation: CLLocationCoordinate2D { get }
    var bName: String? { get }
    
    func distance(to location: BeaconLocation) -> CLLocationDistance
}

extension BeaconLocation {
    func distance(to location: BeaconLocation) -> CLLocationDistance {
        let loc1 = CLLocation(latitude: self.bLocation.latitude, longitude: self.bLocation.longitude)
        let loc2 = CLLocation(latitude: location.bLocation.latitude, longitude: location.bLocation.longitude)
        return loc1.distance(from: loc2)
    }
}
