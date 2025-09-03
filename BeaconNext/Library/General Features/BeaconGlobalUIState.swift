import Foundation

class BeaconGlobalUIState: ObservableObject {    
    @Published var currentPage: BeaconPage? = nil // The sub-page within the home page
    
    // POI viewing page
    @Published var poi: (any BeaconPOI)?

    // Navigation page
    @Published var routeInNavigation: (any BeaconWalkRoute)?
    @Published var navigationStatus: (any BeaconNavigationStatus)? // Current navigation status, if any
    @Published var atIntersection: Bool? // Whether the user is at an intersection (during navigation only), if known

    // Routes page
    @Published var routesFrom: (any BeaconPOI)? // If nil, use current location; otherwise, use the selected POI
    @Published var routesDestination: (any BeaconPOI)? // If nil, use current location; otherwise, use the selected POI
}

public enum BeaconPage: String, CaseIterable, Codable {
    case poi        = "poi"
    case routes     = "routes"
    case navigation = "navigation"
}
