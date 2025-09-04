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
    
    @AppStorage("accessibleMap")            var accessibleMap: Bool = true
    @AppStorage("sayLocation")              var sayLocation: Bool = true
    @AppStorage("sayDirection")             var sayDirection: Bool = true
    @AppStorage("speechRate")               var speechRate: Double = Double(AVSpeechUtteranceDefaultSpeechRate)
    @AppStorage("obstacleRegionSize")       var obstacleRegionSize: Double = 30
    @AppStorage("autoSwitching")            var autoSwitching: Bool = true
    @AppStorage("enabledObjRecog")          var enabledObjRecog: Bool = false
    @AppStorage("enabledObstacleDetection") var enabledObstacleDetection: Bool = true
    @AppStorage("enabledTrafficLights")     var enabledTrafficLights: Bool = false
    @AppStorage("debugShowExploreCam")      var debugShowExploreCam: Bool = false
    @AppStorage("debugTraceGPS")            var debugTraceGPS: Bool = false
    @AppStorage("shownIntro")               var shownIntro: Bool = false
    
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
