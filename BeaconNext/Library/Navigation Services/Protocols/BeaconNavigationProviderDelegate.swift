import CoreLocation

protocol BeaconNavigationProviderDelegate {
    func didStartNavigation()
    func didEndNavigation()
    func didReceiveRoadAngle(_ angle: CLLocationDirection)
    func didReceiveNavigationStatus(_ status: BeaconNavigationStatus)
}
