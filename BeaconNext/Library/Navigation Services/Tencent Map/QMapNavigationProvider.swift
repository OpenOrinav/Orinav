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
    
    var bCoordinate: CLLocationCoordinate2D {
        return coordinate
    }
}

extension TNKWalkRoute: BeaconWalkRoute {
    var bid: String {
        return self.routeID
    }
    
    var bOrigin: any BeaconPOI {
        return self.origin
    }
    
    var bDestination: any BeaconPOI {
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
    var realNavView: TNKWalkNavView
    
    var endNavigation: (() -> Void)?
    var receiveRoadAngle: ((CLLocationDistance) -> Void)?
    
    var navView: UIView {
        return realNavView
    }

    override init() {
        navManager = TNKWalkNavManager.sharedInstance()
        realNavView = TNKWalkNavView(frame: UIScreen.main.bounds)
        
        super.init()
        
        navManager.audioPlayer = TNKAudioPlayer.shared()
        navManager.register(self)
        navManager.navDataSource = self
        realNavView.showUIElements = true
        realNavView.delegate = self
        navManager.register(realNavView)
    }
    
    func planRoutes(
        from: (any BeaconPOI)?,
        to: (any BeaconPOI)?,
        location: BeaconLocation
    ) async -> [any BeaconWalkRoute] {
        let origin = TNKSearchNavPoint()
        origin.coordinate = from?.bCoordinate ?? location.bCoordinate
        origin.title = from?.bName
        origin.poiID = from?.bid

        let destination = TNKSearchNavPoint()
        destination.coordinate = to?.bCoordinate ?? location.bCoordinate
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
                            .map { $0 as (any BeaconWalkRoute) }
                            .sorted { $0.bDistanceMeters < $1.bDistanceMeters }
                        continuation.resume(returning: beaconRoutes)
                    } else {
                        continuation.resume(returning: [])
                    }
                }
            }
        }
    }
    
    func clearState() {
        navManager.stopNav()
        realNavView = TNKWalkNavView(frame: UIScreen.main.bounds)
        realNavView.showUIElements = true
        realNavView.delegate = self
        navManager.register(realNavView)
    }
    
    func walkNavManager(_ manager: TNKWalkNavManager, didUpdate location: TNKLocation) {
        if let receiveRoadAngle = receiveRoadAngle {
            receiveRoadAngle(location.matchedCourse)
        }
    }
    
    func startNavigation(with: any BeaconWalkRoute) {
        navManager.startNav(withRouteID: with.bid)
    }
    
    func navViewCloseButtonClicked(_ navView: TNKBaseNavView) {
        if let endNavigation = endNavigation {
            endNavigation()
        }
    }
}
