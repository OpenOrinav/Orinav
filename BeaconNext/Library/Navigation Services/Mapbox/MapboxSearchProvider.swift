import MapboxSearch

@MainActor
class MapboxSearchProvider: BeaconSearchProvider {
    let searcher = SearchEngine(apiType: .searchBox)
    
    func searchByPOI(poi: String, center: BeaconLocation?) async -> [any BeaconPOI] {
        return await withCheckedContinuation { continuation in
            searcher.forward(query: poi, options: SearchOptions(limit: 10, proximity: center?.bCoordinate)) { result in
                switch result {
                case .success(let suggestions):
                    let wrappedResults = suggestions.map { WrappedMapboxSearchResult(searchResult: $0) }
                    continuation.resume(returning: wrappedResults)
                case .failure(let error):
                    print("MapboxSearchProvider error: \(error)")
                    continuation.resume(returning: [])
                }
            }
        }
    }
}

struct WrappedMapboxSearchResult: BeaconPOI {
    var searchResult: any SearchResult
    
    var bid: String {
        return searchResult.mapboxId!
    }
    
    var bName: String {
        return searchResult.name
    }
    
    var bAddress: String {
        return searchResult.address?.formattedAddress(style: .full) ?? ""
    }
    
    var bCoordinate: CLLocationCoordinate2D {
        return searchResult.coordinate
    }
    
    var bCategory: BeaconPOICategory {
        guard let canonicalId = searchResult.categories?.first?.lowercased() else {
            return .others
        }
        switch canonicalId {
        case let id where id.contains("food"),
            let id where id.contains("restaurant"),
            let id where id.contains("cafe"),
            let id where id.contains("bar"),
            let id where id.contains("bakery"),
            let id where id.contains("deli"),
            let id where id.contains("juice"):
            return .foodAndDrink
        case let id where id.contains("shop"),
            let id where id.contains("mall"),
            let id where id.contains("market"),
            let id where id.contains("store"):
            return .shopping
        case let id where id.contains("health"),
            let id where id.contains("hospital"),
            let id where id.contains("doctor"),
            let id where id.contains("clinic"),
            let id where id.contains("pharmacy"):
            return .healthServices
        case let id where id.contains("office"),
            let id where id.contains("consulting"),
            let id where id.contains("agency"):
            return .office
        case let id where id.contains("school"),
            let id where id.contains("college"),
            let id where id.contains("university"),
            let id where id.contains("kindergarten"),
            let id where id.contains("tutor"):
            return .education
        case let id where id.contains("lodging"),
            let id where id.contains("hotel"),
            let id where id.contains("hostel"),
            let id where id.contains("motel"),
            let id where id.contains("resort"),
            let id where id.contains("bed_and_breakfast"):
            return .lodging
        case let id where id.contains("transport"),
            let id where id.contains("taxi"),
            let id where id.contains("station"),
            let id where id.contains("bus"),
            let id where id.contains("train"),
            let id where id.contains("airport"),
            let id where id.contains("rental"):
            return .transportation
        case let id where id.contains("grocery"),
            let id where id.contains("supermarket"):
            return .grocery
        case let id where id.contains("park"),
            let id where id.contains("trail"),
            let id where id.contains("camp"),
            let id where id.contains("beach"),
            let id where id.contains("forest"),
            let id where id.contains("river"),
            let id where id.contains("lake"):
            return .outdoors
        case let id where id.contains("entertainment"),
            let id where id.contains("cinema"),
            let id where id.contains("theater"),
            let id where id.contains("museum"),
            let id where id.contains("arcade"),
            let id where id.contains("nightclub"):
            return .entertainment
        case let id where id.contains("bank"),
            let id where id.contains("atm"),
            let id where id.contains("financial"),
            let id where id.contains("currency"),
            let id where id.contains("exchange"):
            return .financialServices
        case let id where id.contains("sport"),
            let id where id.contains("gym"),
            let id where id.contains("fitness"):
            return .sportsAndFitness
        case let id where id.contains("government"),
            let id where id.contains("townhall"),
            let id where id.contains("embassy"),
            let id where id.contains("courthouse"),
            let id where id.contains("police"),
            let id where id.contains("fire"):
            return .government
        case let id where id.contains("worship"),
            let id where id.contains("church"),
            let id where id.contains("temple"),
            let id where id.contains("mosque"),
            let id where id.contains("synagogue"):
            return .placeOfWorship
        case let id where id.contains("apartment"),
            let id where id.contains("condo"),
            let id where id.contains("home"),
            let id where id.contains("dormitory"):
            return .residential
        case let id where id.contains("service"),
            let id where id.contains("repair"),
            let id where id.contains("laundry"),
            let id where id.contains("cleaners"),
            let id where id.contains("wash"):
            return .services
        case let id where id.contains("library"),
            let id where id.contains("gallery"),
            let id where id.contains("arts"):
            return .cultural
        default:
            return .others
        }
    }
}
