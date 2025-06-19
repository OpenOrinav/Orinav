import UIKit
import CoreLocation

protocol BeaconNavigationProvider {
    var navView: UIView { get }
    
    var endNavigation: (() -> Void)? { get set }
    var receiveRoadAngle: ((CLLocationDistance) -> Void)? { get set }
    
    func planRoutes(from: (any BeaconPOI)?, to: (any BeaconPOI)?, location: BeaconLocation) async -> [any BeaconWalkRoute]
    func startNavigation(with: any BeaconWalkRoute)
    func clearState()
}
