import CoreLocation

protocol BeaconLocationProviderDelegate {
    func didUpdateLocation(_ location: BeaconLocation)
    func didUpdateHeading(_ heading: CLLocationDirection)
}
