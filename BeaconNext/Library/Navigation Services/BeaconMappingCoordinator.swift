import QMapKit
import TencentNavKit
import Combine

class BeaconMappingCoordinator: ObservableObject {
    var searchProvider: BeaconSearchProvider
    var locationProvider: BeaconLocationProvider
    var locationDelegate: StandardLocationDelegate
    var navigationProvider: BeaconNavigationProvider
    
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
        
        searchProvider = QMapSearchProvider()
        locationProvider = QMapLocationProvider()
        locationDelegate = StandardLocationDelegate()
        navigationProvider = QMapNavigationProvider()
        
        providerReinit()
    }
    
    func providerReinit() {
        locationProvider.delegate = locationDelegate
        cancellable = locationDelegate.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
        
        navigationProvider.endNavigation = { [self] in
            DispatchQueue.main.async {
                self.globalUIState.choosingRoutes = false
                self.globalUIState.routeInNavigation = nil
            }
        }
        navigationProvider.receiveRoadAngle = { [self] angle in
            if globalUIState.routeInNavigation != nil {
                locationDelegate.speakAngularDeviation(from: angle)
            }
        }
    }
}
