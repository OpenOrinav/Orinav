import Foundation
import CoreLocation
import QMapKit

class QMapSearchProvider: NSObject, BeaconSearchProvider, QMSSearchDelegate {
    private let searchManager: QMSSearcher
    private var continuation: CheckedContinuation<[any BeaconPOI], Never>?
    
    override init() {
        self.searchManager = QMSSearcher()

        super.init()
        self.searchManager.delegate = self
    }
    
    func searchByPOI(poi: String, center: CLLocationCoordinate2D?) async -> [any BeaconPOI] {
        return await withCheckedContinuation { cont in
            self.continuation = cont
            
            let option = QMSPoiSearchOption()
            option.keyword = poi
            option.added_fields = "category_code"
            if let center = center {
                option.setBoundaryByNearbyWithCenter(center, radius: 1000, autoExtend: true)
            }
            
            self.searchManager.searchWithPoiSearchOption(option)
        }
    }
    
    // MARK: - QMSSearchDelegate
    
    func search(
        with poiSearchOption: QMSPoiSearchOption,
        didReceive poiSearchResult: QMSPoiSearchResult
    ) {
        continuation?.resume(returning: poiSearchResult.dataArray)
        continuation = nil
    }
    
    func resetSearch() {
        continuation = nil
    }
}

extension QMSPoiData: BeaconPOI {
    public var bid: String {
        id_
    }

    public var bName: String {
        title
    }
    
    public var bAddress: String {
        address
    }
    
    public var bCategory: BeaconPOICategory {
        let code = category_code
        switch code {
        case _ where code.hasPrefix("10"):
            return .foodAndDrink
        case _ where code.hasPrefix("11"):
            return .office
        case _ where code.hasPrefix("1214"):
            return .government
        case _ where code.hasPrefix("1219"):
            return .education
        case _ where code.hasPrefix("1211"):
            return .others
        case _ where code.hasPrefix("1210"):
            return .government
        case _ where code.hasPrefix("12"):
            return .office
        case _ where code.hasPrefix("13"):
            return .shopping
        case _ where code.hasPrefix("1412"):
            return .services
        case _ where code.hasPrefix("1413"):
            return .services
        case _ where code.hasPrefix("14"):
            return .services
        case _ where code.hasPrefix("1616"),
             _ where code.hasPrefix("1617"),
             _ where code.hasPrefix("1612"),
             _ where code.hasPrefix("1613"),
             _ where code.hasPrefix("1619"),
             _ where code.hasPrefix("1618"),
             _ where code.hasPrefix("1621"),
             _ where code.hasPrefix("16"):
            return .entertainment
        case _ where code.hasPrefix("18"):
            return .sportsAndFitness
        case _ where code.hasPrefix("1910"),
             _ where code.hasPrefix("1911"),
             _ where code.hasPrefix("19"):
            return .transportation
        case _ where code.hasPrefix("20"):
            return .healthServices
        case _ where code.hasPrefix("21"):
            return .lodging
        case _ where code.hasPrefix("2211"),
             _ where code.hasPrefix("2212"),
             _ where code.hasPrefix("2213"),
             _ where code.hasPrefix("22"):
            return .outdoors
        case _ where code.hasPrefix("23"):
            return .cultural
        case _ where code.hasPrefix("24"):
            return .education
        case _ where code.hasPrefix("25"):
            return .financialServices
        case _ where code.hasPrefix("26"):
            return .others
        case _ where code.hasPrefix("27"):
            return .transportation
        case _ where code.hasPrefix("28"):
            return .residential
        default:
            return .others
        }
    }

    public var bCoordinate: CLLocationCoordinate2D {
        location
    }
}
