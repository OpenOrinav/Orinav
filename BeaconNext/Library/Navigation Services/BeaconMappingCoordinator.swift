import QMapKit
import TencentNavKit

class BeaconMappingCoordinator: ObservableObject {
    var searchProvider: BeaconSearchProvider
    var locationProvider: BeaconLocationProvider
    var navigationProvider: BeaconNavigationProvider
    
    init() {
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
        navigationProvider = QMapNavigationProvider()
    }
}
