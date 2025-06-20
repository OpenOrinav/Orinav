import SwiftUI
import MapboxNavigationCore
import MapboxNavigationUIKit
import MapboxDirections
import MapboxSearch

class MapboxNavigationServiceProvider: BeaconNavigationProvider {
    var delegate: (any BeaconNavigationProviderDelegate)?
    let mnp = MapboxNavigationProvider(coreConfig: .init())
    
    var routes: NavigationRoutes? // DEBUG
    
    var controller: NavigationViewController?
    
    var navView: UIView {
        if let controller = controller {
            return controller.view
        }
        return UIView()
    }
    
    func planRoutes(
        from: (any BeaconPOI)?,
        to: (any BeaconPOI)?,
        location: BeaconLocation
    ) async -> [any BeaconWalkRoute] {
        do {
            routes = try await mnp.mapboxNavigation.routingProvider().calculateRoutes(
                options: NavigationRouteOptions(
                    coordinates: [from?.bCoordinate ?? location.bCoordinate, to?.bCoordinate ?? location.bCoordinate],
                    profileIdentifier: .walking
                )
            ).value
            return routes!.allRoutes().map { route in
                MapboxRouteWrapper(
                    mapboxRoute: route,
                    origin: from ?? BeaconLocationPOIWrapper(location),
                    destination: to ?? BeaconLocationPOIWrapper(location)
                )
            }
        } catch {
            print("MapboxNavigationServiceProvider error: \(error)")
            return []
        }
    }
    
    func clearState() {
    }
    
    func startNavigation(with: any BeaconWalkRoute) { // DEBUG
        DispatchQueue.main.async {
            self.controller = NavigationViewController(
                navigationRoutes: self.routes!,
                navigationOptions: NavigationOptions(
                    mapboxNavigation: self.mnp.mapboxNavigation,
                    voiceController: self.mnp.routeVoiceController,
                    eventsManager: self.mnp.eventsManager()
                )
            )
            self.controller!.modalPresentationStyle = .fullScreen
        }
    }
}

class BeaconLocationPOIWrapper: BeaconPOI {
    let location: BeaconLocation
    
    init(_ location: BeaconLocation) {
        self.location = location
    }
    
    var bid: String {
        return "poi-wrapper-\(location.bCoordinate.latitude),\(location.bCoordinate.longitude)"
    }
    
    var bName: String {
        return location.bName ?? "Unknown"
    }
    
    var bAddress: String {
        return ""
    }
    
    var bCategory: BeaconPOICategory {
        return .others
    }
    
    var bCoordinate: CLLocationCoordinate2D {
        return location.bCoordinate
    }
}

class MapboxRouteWrapper: BeaconWalkRoute {
    var bid = "mapbox_route"
    
    var mapboxRoute: MapboxDirections.Route
    var bOrigin: any BeaconPOI
    var bDestination: any BeaconPOI
    
    init(mapboxRoute: MapboxDirections.Route, origin: any BeaconPOI, destination: any BeaconPOI) {
        self.mapboxRoute = mapboxRoute
        self.bOrigin = origin
        self.bDestination = destination
    }
    
    var bDistanceMeters: Int {
        return Int(mapboxRoute.distance)
    }
    
    var bTimeMinutes: Int {
        return Int(mapboxRoute.expectedTravelTime / 60.0)
    }
}
