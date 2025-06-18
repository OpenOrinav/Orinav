import QMapKit
import TencentNavKit

class BeaconNavigationCoordinator: ObservableObject {
    var searchProvider: BeaconSearchProvider = QMapSearchProvider()
    var locationProvider: BeaconLocationProvider = QMapLocationProvider()
    
    init() {
        // Retrieve API key and meet compliance requirements
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "TencentAPIKey") as? String else {
            fatalError("Missing TencentAPIKey in Info.plist")
        }
        
        QMapServices.shared().setPrivacyAgreement(true) // In practice we would add a popup, but that could be done later
        TNKNavServices.shared().setPrivacyAgreement(true)
        QMapServices.shared().apiKey = apiKey
        TNKNavServices.shared().key = apiKey
        QMSSearchServices.shared().apiKey = apiKey
    }
}
