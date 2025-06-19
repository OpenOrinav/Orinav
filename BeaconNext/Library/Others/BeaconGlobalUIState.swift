import Foundation

class BeaconGlobalUIState: ObservableObject {
    @Published var routeInNavigation: (any BeaconWalkRoute)? // If nil, not in navigation
    
    @Published var choosingRoutes: Bool = false
    @Published var from: (any BeaconPOI)? // If nil, use current location; otherwise, use the selected POI
    @Published var destination: (any BeaconPOI)? // If nil, use current location; otherwise, use the selected POI
}
