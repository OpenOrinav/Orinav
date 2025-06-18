import CoreLocation

protocol BeaconSearchProvider {
    func searchByPOI(poi: String, center: CLLocationCoordinate2D?) async throws -> [BeaconPOI]
}
