import Foundation
import QMapKit

class BeaconSearchDelegateSimple: NSObject, ObservableObject, QMSSearchDelegate {
    private let searchManager: QMSSearcher
    
    override init() {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "TencentAPIKey") as? String else {
            fatalError("Missing TencentAPIKey in Info.plist")
        }
        QMSSearchServices.shared().apiKey = apiKey
        
        self.searchManager = QMSSearcher()
        super.init()
        self.searchManager.delegate = self
    }
    
    @Published var lastSearchResults: [QMSPoiData] = []
    func searchPOIByKeywords(_ keyword: String, center: CLLocationCoordinate2D?) {
        let option = QMSPoiSearchOption()
        option.keyword = keyword
        option.added_fields = "category_code"
        if let center = center {
            option.setBoundaryByNearbyWithCenter(center, radius: 1000, autoExtend: true)
        }
        self.searchManager.searchWithPoiSearchOption(option)
    }
    
    func search(
        with poiSearchOption: QMSPoiSearchOption,
        didReceive poiSearchResult: QMSPoiSearchResult
    ) {
        DispatchQueue.main.async {
            self.lastSearchResults = poiSearchResult.dataArray
        }
    }
    
    func search(
        with searchOption: QMSSearchOption,
        didFailWithError error: any Error
    ) {
        print("An error occurred while searching")
        print(error)
    }
    
    func resetSearch() {
        lastSearchResults.removeAll()
    }
}
