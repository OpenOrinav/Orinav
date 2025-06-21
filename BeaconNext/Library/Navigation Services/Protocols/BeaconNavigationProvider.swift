import SwiftUI
import CoreLocation

@MainActor
protocol BeaconNavigationProvider {
    var delegate: BeaconNavigationProviderDelegate? { get set }
    
    /// Query the routes between two points. Also performs any necessary setup for beginning navigation.
    func planRoutes(from: (any BeaconPOI)?, to: (any BeaconPOI)?, location: BeaconLocation) async -> [any BeaconWalkRoute]
    /// Starts navigation with the provided route. It is expected that `planRoutes` has been called beforehand.
    func startNavigation(with: any BeaconWalkRoute) async -> AnyView
    /// Manually called by the provider to clear any state and stop navigation.
    func clearState()
}
