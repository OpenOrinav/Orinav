import QMapKit
import TencentNavKit
import TNKAudioPlayer
import CoreLocation

class BeaconNavigationDelegateSimple: NSObject, ObservableObject, TNKWalkNavDelegate, TNKWalkNavDataSource, TNKWalkNavViewDelegate {
    let navManager: TNKWalkNavManager
    var navView: TNKWalkNavView?
    
    override init() {
        navManager = TNKWalkNavManager.sharedInstance()
        super.init()
        navManager.audioPlayer = TNKAudioPlayer.shared()
        navManager.register(self)
        navManager.navDataSource = self
    }
    
    @Published var lastSearchResults: [TNKWalkRoute] = []
    @Published var searchLoading = false
    @Published var isNavigating: Bool = false
    
    func resetSearchResults() {
        lastSearchResults.removeAll()
    }
    
    func planRoutes(
        from: QMSPoiData?,
        to: QMSPoiData?,
        location: CLLocationCoordinate2D?
    ) {
        searchLoading = true
        
        let origin = TNKSearchNavPoint()
        origin.coordinate = from?.location ?? location!
        origin.title = from?.title
        origin.poiID = from?.id_
        
        let destination = TNKSearchNavPoint()
        destination.coordinate = to?.location ?? location!
        destination.title = to?.title
        destination.poiID = to?.id_
        
        let request = TNKRouteRequest()
        request.origin = origin
        request.destination = destination

        navManager.searchRoutes(with: request) { result, error in
            DispatchQueue.main.async {
                self.searchLoading = false
            }
            
            if let error = error {
                print("Error searching routes: \(error)")
                return
            }
            
            DispatchQueue.main.async {
                if let result = result {
                    self.lastSearchResults = result.routes.sorted {
                        $0.totalDistance < $1.totalDistance
                    }
                }
            }
        }
    }
    
    func startNavigation(with: TNKWalkRoute) {
        navManager.startNav(withRouteID: with.routeID)
        isNavigating = true
    }
    
    func navViewCloseButtonClicked(_ navView: TNKBaseNavView) {
        DispatchQueue.main.async {
            self.isNavigating = false
        }
    }
    
    var lastDirection: String? = nil
    var lastFacingAngle: Double? = nil
    
    func walkNavManager(_ manager: TNKWalkNavManager, didUpdate location: TNKLocation) {
        // location.matchedCourse 道路方向
        // HeadingManager.shared.getValidHeading()! 手机方向
        let roadAngle = location.matchedCourse
        guard let facingAngle = HeadingManager.shared.getValidHeading() else {
            print("Direction Not Avaliable")
            return
        }
        
        let signedDiff = (facingAngle - roadAngle + 540).truncatingRemainder(dividingBy: 360) - 180
        
        if abs(signedDiff) >= 20 {
            let currentDirection = direction(from: signedDiff)
            
            if currentDirection != lastDirection || (lastFacingAngle != nil && abs(facingAngle - lastFacingAngle!) > 5) {
//                print(currentDirection)
                BeaconTTSService.shared.speak("Head \(currentDirection)")
                lastDirection = currentDirection
                lastFacingAngle = facingAngle
            }
        } else {
            lastDirection = nil
            lastFacingAngle = nil
        }
    }
    
    func direction(from angle: Double) -> String {
        let normalized = angle >= 0 ? angle : 360 + angle
        let adjusted = (normalized + 15).truncatingRemainder(dividingBy: 360)
        let hour = Int(adjusted / 30)
        let hourLabels = [12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
        return "\(hourLabels[hour]) o'clock"
    }
}
