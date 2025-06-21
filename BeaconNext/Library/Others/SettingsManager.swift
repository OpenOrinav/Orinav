import SwiftUI

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    private let userDefaultsKey = "mapProvider"

    @Published var mapProvider: MapProvider {
        didSet {
            UserDefaults.standard.set(mapProvider.rawValue, forKey: "mapProvider")
        }
    }

    private init() {
        if let stored = UserDefaults.standard.string(forKey: userDefaultsKey),
           let provider = MapProvider(rawValue: stored) {
            mapProvider = provider
        } else {
            mapProvider = .location
        }
    }
}

public enum MapProvider: String, CaseIterable {
    case location = "Automatic"
    case tencent = "Tencent Map (China only)"
    case mapbox = "Mapbox (Global)"
}
