import SwiftUI
import CoreLocation

protocol BeaconNavigationProvider {
    var delegate: BeaconNavigationProviderDelegate? { get set }
    
    func planRoutes(from: (any BeaconPOI)?, to: (any BeaconPOI)?, location: BeaconLocation) async -> [any BeaconWalkRoute]

    func startNavigation(with: any BeaconWalkRoute) -> AnyView
    func clearState()
}
