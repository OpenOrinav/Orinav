import Foundation
import CoreLocation

class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    
    @Published var favorites: [any BeaconPOI] = [] {
        didSet {
            saveFavoritesToDisk()
        }
    }

    private let storageKey = "SavedFavorites"

    private init() {
        loadFavoritesFromDisk()
    }

    func addFavorite(poi: any BeaconPOI) {
        if !favorites.contains(where: { $0.bid == poi.bid }) {
            favorites.append(poi)
        }
    }

    func removeFavorite(id: String) {
        favorites.removeAll { $0.bid == id }
    }

    // MARK: - Local Persistence

    private func saveFavoritesToDisk() {
        let simplified = favorites.map { SimplifiedPOI(from: $0) }
        if let data = try? JSONEncoder().encode(simplified) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadFavoritesFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let simplified = try? JSONDecoder().decode([SimplifiedPOI].self, from: data) else {
            return
        }
        self.favorites = simplified
    }
}

// MARK: - Codable Simplified POI

private struct SimplifiedPOI: Codable, BeaconPOI {
    let bid: String
    let bName: String
    let bAddress: String
    let lat: Double?
    let lng: Double?
    let category: String
    
    var bCoordinate: CLLocationCoordinate2D? {
        guard let lat = lat, let lng = lng else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    
    var bCategory: BeaconPOICategory {
        return BeaconPOICategory(rawValue: category) ?? .others
    }
    
    init(from poi: any BeaconPOI) {
        self.bid = poi.bid
        self.bName = poi.bName
        self.bAddress = poi.bAddress
        self.category = poi.bCategory.rawValue
        self.lat = poi.bCoordinate?.latitude
        self.lng = poi.bCoordinate?.longitude
    }
}
