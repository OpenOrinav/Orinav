import SwiftUI
import CoreLocation

@MainActor
protocol BeaconNavigationProvider {
    var delegate: BeaconNavigationProviderDelegate? { get set }
    
    func planRoutes(from: (any BeaconPOI)?, to: (any BeaconPOI)?, location: BeaconLocation) async -> [any BeaconWalkRoute]
    func startNavigation(with: any BeaconWalkRoute) async -> AnyView
    func clearState()
}
