import AVFoundation
import Foundation
import SwiftUI

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @AppStorage("mapProvider") private var mapProviderRaw: String = MapProvider.location.rawValue
    var mapProvider: MapProvider {
        get { MapProvider(rawValue: mapProviderRaw) ?? .location }
        set { mapProviderRaw = newValue.rawValue }
    }
    @AppStorage("exploreFeature") private var exploreFeatureRaw: String = ExploreFeatureOption.none.rawValue
    var exploreFeature: ExploreFeatureOption {
        get { ExploreFeatureOption(rawValue: exploreFeatureRaw) ?? .none }
        set { exploreFeatureRaw = newValue.rawValue }
    }
    
    @AppStorage("accessibleMap")            var accessibleMap: Bool = true
    @AppStorage("sayLocation")              var sayLocation: Bool = true
    @AppStorage("sayDirection")             var sayDirection: Bool = true
    @AppStorage("speechRate")               var speechRate: Double = Double(AVSpeechUtteranceDefaultSpeechRate)
    @AppStorage("obstacleRegionSize")       var obstacleRegionSize: Double = 30
    @AppStorage("autoSwitching")            var autoSwitching: Bool = true
    @AppStorage("debugShowExploreCam")      var debugShowExploreCam: Bool = false
    @AppStorage("debugTraceGPS")            var debugTraceGPS: Bool = false
    @AppStorage("shownIntro")               var shownIntro: Bool = false
    @AppStorage("lastShownChangelog")       var lastShownChangelog: Int = 0

    @AppStorage("MGLMapboxMetricsEnabled")  var mapboxTelemetry: Bool = false // Don't show this, who wants to fuss with that?
    
    private init() {}
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

public enum ExploreFeatureOption: String, CaseIterable {
    case none = "None"
    case obstacles = "Obstacles"
    case trafficLights = "Traffic Lights"
    case objects = "Identify Objects"
    
    var localizedName: LocalizedStringResource {
        switch self {
        case .none: return "None"
        case .obstacles: return "Obstacles"
        case .trafficLights: return "Traffic Lights"
        case .objects: return "Identify Objects"
        }
    }
}
