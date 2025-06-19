import CoreLocation

protocol BeaconLocation {
    var bCoordinate: CLLocationCoordinate2D { get }
    var bName: String? { get }
    
    func distance(to location: BeaconLocation) -> CLLocationDistance
}

extension BeaconLocation {
    func distance(to location: BeaconLocation) -> CLLocationDistance {
        let loc1 = CLLocation(latitude: self.bCoordinate.latitude, longitude: self.bCoordinate.longitude)
        let loc2 = CLLocation(latitude: location.bCoordinate.latitude, longitude: location.bCoordinate.longitude)
        return loc1.distance(from: loc2)
    }
    
    func distance(to location: CLLocationCoordinate2D) -> CLLocationDistance {
        let loc1 = CLLocation(latitude: self.bCoordinate.latitude, longitude: self.bCoordinate.longitude)
        let loc2 = CLLocation(latitude: location.latitude, longitude: location.longitude)
        return loc1.distance(from: loc2)
    }
}
