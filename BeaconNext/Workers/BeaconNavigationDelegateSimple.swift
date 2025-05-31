import QMapKit
import TencentNavKit
import TNKAudioPlayer

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
    }
}
