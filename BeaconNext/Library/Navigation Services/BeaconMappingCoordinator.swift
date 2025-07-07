import QMapKit
import TencentNavKit
import Combine
import CoreLocation

private extension CLLocationCoordinate2D {
    var isInChinaMainland: Bool {
        let lat = self.latitude
        let lon = self.longitude
        return (lat >= 18.197700914 && lat <= 53.4588044297) && (lon >= 73.6753792663 && lon <= 135.026311477)
    }
}

@MainActor
class BeaconMappingCoordinator: ObservableObject {
    var searchProvider: BeaconSearchProvider
    
    var locationProvider: BeaconLocationProvider
    var locationDelegate: StandardLocationDelegate
    
    var navigationProvider: BeaconNavigationProvider
    var navigationDelegate: StandardNavigationDelegate
    
    var globalUIState: BeaconGlobalUIState
    
    private var cancellable: AnyCancellable?
    
    init(globalUIState: BeaconGlobalUIState) {
        self.globalUIState = globalUIState
        
        // Set Tencent Map API keys
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "TencentAPIKey") as? String else {
            fatalError("Missing TencentAPIKey in Info.plist")
        }
        QMapServices.shared().setPrivacyAgreement(true)
        TNKNavServices.shared().setPrivacyAgreement(true)
        QMapServices.shared().apiKey = apiKey
        TNKNavServices.shared().key = apiKey
        QMSSearchServices.shared().apiKey = apiKey

        switch SettingsManager.shared.mapProvider {
        case .location:
            // Quickly use time zone to determine the location
            if TimeZone.current.identifier == "Asia/Shanghai" {
                locationProvider = QMapLocationProvider()
                searchProvider = QMapSearchProvider()
                navigationProvider = QMapNavigationServiceProvider()
            } else {
                locationProvider = MapboxLocationProvider()
                searchProvider = MapboxSearchProvider()
                navigationProvider = MapboxNavigationServiceProvider()
            }
        case .tencent:
            locationProvider = QMapLocationProvider()
            searchProvider = QMapSearchProvider()
            navigationProvider = QMapNavigationServiceProvider()
        case .mapbox:
            locationProvider = MapboxLocationProvider()
            searchProvider = MapboxSearchProvider()
            navigationProvider = MapboxNavigationServiceProvider()
        }
        
        locationDelegate = StandardLocationDelegate(globalUIState: globalUIState)
        navigationDelegate = StandardNavigationDelegate(globalUIState: globalUIState, locationDelegate: locationDelegate)
        
        DeviceMotionManager.shared.delegates.append(locationDelegate)
        DeviceMotionManager.shared.delegates.append(navigationDelegate)
        
        providerReinit()
    }
    
    func providerReinit() {
        locationProvider.delegate = locationDelegate
        navigationProvider.delegate = navigationDelegate
        cancellable = locationDelegate.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
    }
}
