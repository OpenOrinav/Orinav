import CoreLocation

protocol BeaconNavigationProviderDelegate {
    func onEndNavigation()
    func onReceiveRoadAngle(_ angle: CLLocationDirection)
    func onReceiveNavigationStatus(_ status: BeaconNavigationStatus)
    func onReceiveHaptics(_ angle: CLLocationDirection, heading: CLLocationDirection)
}
