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
    
    func resetSearch() {
        lastSearchResults.removeAll()
    }
}
