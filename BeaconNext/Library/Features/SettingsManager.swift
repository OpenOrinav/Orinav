import SwiftUI

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    private let userDefaultsKey = "mapProvider"
    private let shownIntroKey = "shownIntro"

    @Published var mapProvider: MapProvider {
        didSet {
            UserDefaults.standard.set(mapProvider.rawValue, forKey: "mapProvider")
        }
    }

    @Published var shownIntro: Bool {
        didSet {
            UserDefaults.standard.set(shownIntro, forKey: shownIntroKey)
        }
    }

    private init() {
        // Load mapProvider
        if let stored = UserDefaults.standard.string(forKey: userDefaultsKey),
           let provider = MapProvider(rawValue: stored) {
            mapProvider = provider
        } else {
            mapProvider = .location
        }
        // Load shownIntro flag
        if UserDefaults.standard.object(forKey: shownIntroKey) != nil {
            shownIntro = UserDefaults.standard.bool(forKey: shownIntroKey)
        } else {
            shownIntro = false
        }
    }
}

public enum MapProvider: String, CaseIterable {
    case location = "Automatic"
    case tencent = "Tencent Map (China only)"
    case mapbox = "Mapbox (Global)"
}
