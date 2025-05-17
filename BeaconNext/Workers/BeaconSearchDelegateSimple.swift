import Foundation
import AMapSearchKit

class BeaconSearchDelegateSimple: NSObject, ObservableObject, AMapSearchDelegate {
    private let searchManager: AMapSearchAPI
    
    override init() {
        self.searchManager = AMapSearchAPI()
        super.init()
        self.searchManager.delegate = self
    }
    
    @Published var lastSearchResults: [AMapPOI] = []
    func searchPOIByKeywords(_ request: AMapPOIKeywordsSearchRequest) {
        searchManager.aMapPOIKeywordsSearch(request)
    }

    func onPOISearchDone(_ request: AMapPOISearchBaseRequest!, response: AMapPOISearchResponse!) {
        guard let pois = response.pois else { return }
        lastSearchResults = pois
    }
    
    @Published var lastRouteSearchResults: [AMapPath] = []
    func searchWalkingRoute(from: AMapPOI?, to: AMapPOI?, currentLocation: AMapGeoPoint?) {
        let request = AMapWalkingRouteSearchRequest()
        request.origin = from?.location ?? currentLocation
        request.destination = to?.location ?? currentLocation
        request.alternativeRoute = 2
        if request.origin == nil || request.destination == nil {
            return
        }
        searchManager.aMapWalkingRouteSearch(request)
    }
    
    func onRouteSearchDone(_ request: AMapRouteSearchBaseRequest!, response: AMapRouteSearchResponse!) {
        guard let route = response.route else { return }
        lastRouteSearchResults = route.paths.sorted { $0.distance < $1.distance }
    }
    
    
    func resetSearch() {
        lastSearchResults.removeAll()
    }
    
    func resetRouteSearch() {
        lastRouteSearchResults.removeAll()
    }
}
