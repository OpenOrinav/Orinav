import SwiftUI
import TencentNavKit

class QMapNavigationServiceProvider: NSObject, BeaconNavigationProvider, TNKWalkNavDataSource {
    let navManager: TNKWalkNavManager
    var realNavView: TNKWalkNavView?
    
    var delegate: BeaconNavigationProviderDelegate?
    
    override init() {
        navManager = TNKWalkNavManager.sharedInstance()
        navManager.audioPlayer = nil
        super.init()
        
        navManager.register(self)
        navManager.navDataSource = self
    }
    
    func planRoutes(
        from: (any BeaconPOI)?,
        to: (any BeaconPOI)?,
        location: BeaconLocation
    ) async -> [any BeaconWalkRoute] {
        if realNavView == nil {
            realNavView = TNKWalkNavView(frame: UIScreen.main.bounds)
            realNavView!.showUIElements = true
            realNavView!.delegate = self
            navManager.register(realNavView!)
        }
        
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
        realNavView = nil
    }
    
    func startNavigation(with: any BeaconWalkRoute) async -> AnyView {
        navManager.startNav(withRouteID: with.bid)
        delegate?.didStartNavigation()
        return AnyView(QMapNavigationView(navManager: self, navView: realNavView!))
    }
}

extension QMapNavigationServiceProvider: TNKWalkNavDelegate {
    func walkNavManager(_ manager: TNKWalkNavManager, didUpdate location: TNKLocation) {
        delegate?.didReceiveRoadAngle(location.matchedCourse)
    }
    
    func walkNavManager(_ manager: TNKWalkNavManager, naviTTS: TNKNavTTS) -> Int32 {
        if BeaconTTSService.shared.currentPriority == .navigation || BeaconTTSService.shared.currentPriority == .navigationImportant {
            return 0 // Still playing another message
        }
        BeaconTTSService.shared.speak(naviTTS.ttsString, type: naviTTS.voiceType.rawValue == 1 ? .navigationImportant : .navigation, language: "zh-CN") // Tencent Map always speaks in Chinese
        return 1
    }
    
    func walkNavManager(_ manager: TNKWalkNavManager, update navigationData: TNKWalkNavigationData) {
        delegate?.didReceiveNavigationStatus(navigationData)
    }
}

extension QMapNavigationServiceProvider: TNKWalkNavViewDelegate {
    func navViewCloseButtonClicked(_ navView: TNKBaseNavView) {
        clearState()
        delegate?.didEndNavigation()
    }
}

struct QMapNavigationView: UIViewRepresentable {
    let navManager: any BeaconNavigationProvider
    let navView: TNKWalkNavView
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.addSubview(navView)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}

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
    
    var bDescription: String {
        return self.recommendReason
    }
}

extension TNKWalkNavigationData: BeaconNavigationStatus {
    var bNextRoad: String? {
        return nextRoadName
    }
    
    var bCurrentRoad: String {
        return currentRoadName
    }
    
    var bDistanceToNextSegmentMeters: Int {
        return Int(nextDistanceLeft)
    }
    
    var bTotalDistanceRemainingMeters: Int {
        return Int(totalDistanceLeft)
    }
    
    var bCurrentSpeed: Int {
        return Int(currentSpeed)
    }
    
    var bTimeRemainingSeconds: Int {
        return Int(totalTimeLeft * 60)
    }
    
    var bTurnType: BeaconTurnType {
        switch intersectionType {
        case 1: return .straight
        case 2: return .left
        case 3: return .right
        case 4: return .slightLeft // Guess
        case 5: return .slightRight // Guess
            // There doesn't appear to be a U-turn type
        case 60: return .stop
        default: return .straight
        }
    }
}
