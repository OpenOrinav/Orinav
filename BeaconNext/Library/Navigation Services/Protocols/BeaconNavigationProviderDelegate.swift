import CoreLocation

protocol BeaconNavigationProviderDelegate {
    func shouldEndNavigation()
    func didReceiveRoadAngle(_ angle: CLLocationDirection)
    func didReceiveNavigationStatus(_ status: BeaconNavigationStatus)
}
