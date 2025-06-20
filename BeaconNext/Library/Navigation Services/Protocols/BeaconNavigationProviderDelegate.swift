import CoreLocation

protocol BeaconNavigationProviderDelegate {
    func onEndNavigation()
    func onReceiveRoadAngle(_ angle: CLLocationDirection)
    func onReceiveNavigationStatus(_ status: BeaconNavigationStatus)
}
