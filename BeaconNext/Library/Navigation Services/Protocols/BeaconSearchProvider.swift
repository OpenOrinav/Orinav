import CoreLocation

protocol BeaconSearchProvider {
    func searchByPOI(poi: String, center: BeaconLocation?) async -> [any BeaconPOI]
}
