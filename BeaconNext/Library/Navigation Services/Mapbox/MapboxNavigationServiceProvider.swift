import SwiftUI
import MapboxNavigationCore
import MapboxNavigationUIKit
import MapboxDirections
import MapboxSearch
import Combine

class MapboxNavigationServiceProvider: BeaconNavigationProvider, NavigationViewControllerDelegate {
    var delegate: (any BeaconNavigationProviderDelegate)?
    let mnp: MapboxNavigationProvider
    
    var routes: NavigationRoutes?
    var controller: NavigationViewController?
    
    init() {
        mnp = MapboxNavigationProvider(coreConfig: .init(credentials: .init(), locationSource: .live))
    }
    
    func planRoutes(
        from: (any BeaconPOI)?,
        to: (any BeaconPOI)?,
        location: BeaconLocation
    ) async -> [any BeaconWalkRoute] {
        do {
            let coreRef = mnp.mapboxNavigation
            let routeResponse = try await coreRef.routingProvider().calculateRoutes(
                options: NavigationRouteOptions(
                    waypoints: [
                        Waypoint(coordinate: from?.bCoordinate ?? location.bCoordinate, name: from?.bName),
                        Waypoint(coordinate: to?.bCoordinate ?? location.bCoordinate, name: to?.bName)
                    ],
                    profileIdentifier: .walking,
                    queryItems: [URLQueryItem(name: "alternatives", value: "true")]
                )
            ).value
            
            var resultingRoutes: [MapboxRouteWrapper] = []
            resultingRoutes.append(MapboxRouteWrapper(
                mapboxRoute: routeResponse.mainRoute,
                origin: from ?? BeaconLocationPOIWrapper(location),
                destination: to ?? BeaconLocationPOIWrapper(location)
            ))
            for alternative in routeResponse.alternativeRoutes {
                resultingRoutes.append(MapboxRouteWrapper(
                    mapboxRoute: alternative,
                    origin: from ?? BeaconLocationPOIWrapper(location),
                    destination: to ?? BeaconLocationPOIWrapper(location)
                ))
            }
            self.routes = routeResponse
            return resultingRoutes
        } catch {
            print("MapboxNavigationServiceProvider error: \(error)")
            return []
        }
    }
    
    func navigationViewControllerDidDismiss(
        _ navigationViewController: NavigationViewController,
        byCanceling canceled: Bool
    ) {
        self.clearState()
        self.delegate?.shouldEndNavigation()
    }
    
    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didUpdate progress: RouteProgress,
        with location: CLLocation,
        rawLocation: CLLocation
    ) {
        // TODO self.delegate?.didReceiveNavigationStatus(progress)
        self.delegate?.didReceiveRoadAngle(location.course)
    }

    func clearState() {
        routes = nil
        mnp.mapboxNavigation.tripSession().setToIdle()
    }
    
    func startNavigation(with: any BeaconWalkRoute) async -> AnyView { // DEBUG
        if routes!.mainRoute.routeId.description != with.bid {
            routes = await routes!.selecting(alternativeRoute: routes!.alternativeRoutes.first { $0.routeId.description == with.bid }!)
        }
        
        mnp.mapboxNavigation.tripSession().startActiveGuidance(with: routes!, startLegIndex: 0)
        
        controller = NavigationViewController(
            navigationRoutes: routes!,
            navigationOptions: NavigationOptions(
                mapboxNavigation: mnp.mapboxNavigation,
                voiceController: mnp.routeVoiceController,
                eventsManager: mnp.eventsManager()
            )
        )
        controller!.delegate = self
        controller!.modalPresentationStyle = .fullScreen
        return AnyView(MapboxNavigationContainerView(controller: controller!))
    }
}

struct MapboxNavigationContainerView: UIViewControllerRepresentable {
    let controller: NavigationViewController
    
    func makeUIViewController(context: Context) -> NavigationViewController {
        controller
    }
    
    func updateUIViewController(_ vc: NavigationViewController, context: Context) {
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
    var bid: String
    var routeId: RouteId
    var bDistanceMeters: Int
    var bTimeMinutes: Int
    var bOrigin: any BeaconPOI
    var bDestination: any BeaconPOI
    var bDescription: String
    
    init(mapboxRoute: NavigationRoute, origin: any BeaconPOI, destination: any BeaconPOI) {
        self.bid = mapboxRoute.routeId.description
        self.routeId = mapboxRoute.routeId
        self.bOrigin = origin
        self.bDestination = destination
        self.bDistanceMeters = Int(mapboxRoute.route.distance)
        self.bTimeMinutes = Int(mapboxRoute.route.expectedTravelTime / 60.0)
        self.bDescription = "via \(mapboxRoute.route.description)"
    }
    
    init(mapboxRoute: AlternativeRoute, origin: any BeaconPOI, destination: any BeaconPOI) {
        self.bid = mapboxRoute.routeId.description
        self.routeId = mapboxRoute.routeId
        self.bOrigin = origin
        self.bDestination = destination
        self.bDistanceMeters = Int(mapboxRoute.route.distance)
        self.bTimeMinutes = Int(mapboxRoute.route.expectedTravelTime / 60.0)
        self.bDescription = "via \(mapboxRoute.route.description)"
    }
}
