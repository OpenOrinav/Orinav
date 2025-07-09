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
    
    @Published var accessibleMap: Bool {
        didSet {
            UserDefaults.standard.set(accessibleMap, forKey: "accessibleMap")
        }
    }
    
    @Published var sayLocation: Bool {
        didSet {
            UserDefaults.standard.set(sayLocation, forKey: "sayLocation")
        }
    }
    
    @Published var sayDirection: Bool {
        didSet {
            UserDefaults.standard.set(sayDirection, forKey: "sayDirection")
        }
    }
    
    @Published var obstacleRegionSize: Double {
        didSet {
            UserDefaults.standard.set(obstacleRegionSize, forKey: "obstacleRegionSize")
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
        // Load accessibleMap flag
        if UserDefaults.standard.object(forKey: "accessibleMap") != nil {
            accessibleMap = UserDefaults.standard.bool(forKey: "accessibleMap")
        } else {
            accessibleMap = true
        }
        // Load sayLocation flag
        if UserDefaults.standard.object(forKey: "sayLocation") != nil {
            sayLocation = UserDefaults.standard.bool(forKey: "sayLocation")
        } else {
            sayLocation = true
        }
        // Load sayDirection flag
        if UserDefaults.standard.object(forKey: "sayDirection") != nil {
            sayDirection = UserDefaults.standard.bool(forKey: "sayDirection")
        } else {
            sayDirection = true
        }
        // Load obstacleRegionSize
        if UserDefaults.standard.object(forKey: "obstacleRegionSize") != nil {
            obstacleRegionSize = UserDefaults.standard.double(forKey: "obstacleRegionSize")
        } else {
            obstacleRegionSize = 30
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
    
    var localizedName: LocalizedStringResource {
        switch self {
        case .location: return "Automatic"
        case .tencent: return "Tencent Map (China only)"
        case .mapbox: return "Mapbox (Global)"
        }
    }
}
