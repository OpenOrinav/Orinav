import Foundation
import AMapSearchKit

class BeaconSearchDelegateSimple: NSObject, ObservableObject, AMapSearchDelegate {
    @Published var lastSearchResults: [AMapPOI] = []
    private let searchManager: AMapSearchAPI
    
    override init() {
        self.searchManager = AMapSearchAPI()
        super.init()
        self.searchManager.delegate = self
    }
    
    func search(_ request: AMapPOIKeywordsSearchRequest) {
        searchManager.aMapPOIKeywordsSearch(request)
    }

    func onPOISearchDone(_ request: AMapPOISearchBaseRequest!, response: AMapPOISearchResponse!) {
        guard let pois = response.pois else { return }
        self.lastSearchResults = pois
        print(pois)
    }
}
