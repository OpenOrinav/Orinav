import TencentNavKit
import TNKAudioPlayer

extension TNKSearchNavPoint: BeaconPOI {
    var bid: String {
        return poiID ?? "defaultLocation"
    }
    
    var bName: String {
        return title ?? "Location"
    }
    
    var bAddress: String {
        return ""
    }
    
    var bCategory: BeaconPOICategory {
        return .others
    }
    
    var bLocation: CLLocationCoordinate2D {
        return coordinate
    }
}

extension TNKWalkRoute: BeaconWalkRoute {
    var bid: String {
        return self.routeID
    }
    
    var bOrigin: BeaconPOI {
        return self.origin
    }
    
    var bDestination: BeaconPOI {
        return self.destination
    }
    
    var bDistanceMeters: Int {
        return Int(self.totalDistance)
    }
    
    var bTimeMinutes: Int {
        return Int(self.totalTime)
    }
}

class QMapNavigationProvider: NSObject, BeaconNavigationProvider, TNKWalkNavDelegate, TNKWalkNavViewDelegate, TNKWalkNavDataSource {
    let navManager: TNKWalkNavManager
    let navView: TNKWalkNavView
    
    var endNavigation: (() -> Void)?

    override init() {
        navManager = TNKWalkNavManager.sharedInstance()
        super.init()
        navManager.audioPlayer = TNKAudioPlayer.shared()
        navManager.register(self)
        navManager.navDataSource = self
        
        navView = TNKWalkNavView(frame: UIScreen.main.bounds)
        navView.showUIElements = true
        navView.delegate = self
        navManager.register(navView)
    }
    
    func planRoutes(
        from: BeaconPOI?,
        to: BeaconPOI?,
        location: CLLocationCoordinate2D?
    ) async -> [BeaconWalkRoute] {
        let origin = TNKSearchNavPoint()
        origin.coordinate = from?.bLocation ?? location!
        origin.title = from?.bName
        origin.poiID = from?.bid

        let destination = TNKSearchNavPoint()
        destination.coordinate = to?.bLocation ?? location!
        destination.title = to?.bName
        destination.poiID = to?.bid

        let request = TNKRouteRequest()
        request.origin = origin
        request.destination = destination

        return await withCheckedContinuation { continuation in
            navManager.searchRoutes(with: request) { result, error in
                DispatchQueue.main.async {
                    if let routes = result?.routes {
                        let beaconRoutes = routes
                            .map { $0 as BeaconWalkRoute }
                            .sorted { $0.bDistanceMeters < $1.bDistanceMeters }
                        continuation.resume(returning: beaconRoutes)
                    } else {
                        continuation.resume(returning: [])
                    }
                }
            }
        }
    }
    
    func startNavigation(with: BeaconWalkRoute) {
        navManager.startNav(withRouteID: with.bid)
    }
    
    func navViewCloseButtonClicked(_ navView: TNKBaseNavView) {
        if let endNavigation = endNavigation {
            endNavigation()
        }
    }
}
