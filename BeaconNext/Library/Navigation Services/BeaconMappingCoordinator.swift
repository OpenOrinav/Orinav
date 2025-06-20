import QMapKit
import TencentNavKit
import Combine

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
        
        searchProvider = MapboxSearchProvider()
        locationProvider = MapboxLocationProvider()
        locationDelegate = StandardLocationDelegate()
        navigationProvider = MapboxNavigationServiceProvider()
        navigationDelegate = StandardNavigationDelegate(globalUIState: globalUIState, locationDelegate: locationDelegate)
        
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
