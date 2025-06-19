import Foundation
import QMapKit

class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    
    @Published var favorites: [QMSPoiData] = [] {
        didSet {
            saveFavoritesToDisk()
        }
    }

    private let storageKey = "SavedFavorites"

    private init() {
        loadFavoritesFromDisk()
    }

    func addFavorite(poi: QMSPoiData) {
        if !favorites.contains(where: { $0.id_ == poi.id_ }) {
            favorites.append(poi)
        }
    }

    func removeFavorite(id: String) {
        favorites.removeAll { $0.id_ == id }
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
        self.favorites = simplified.map { $0.toQMSPoiData() }
    }
}

// MARK: - Codable Simplified POI

private struct SimplifiedPOI: Codable {
    let id_: String
    let title: String
    let address: String
    let lat: Double
    let lng: Double
    let category_code: String

    init(from poi: QMSPoiData) {
        self.id_ = poi.id_
        self.title = poi.title
        self.address = poi.address
        self.lat = poi.location.latitude
        self.lng = poi.location.longitude
        self.category_code = poi.category_code
    }

    func toQMSPoiData() -> QMSPoiData {
        let poi = QMSPoiData()
        poi.id_ = id_
        poi.title = title
        poi.address = address
        poi.location = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        poi.category_code = category_code
        return poi
    }
}
