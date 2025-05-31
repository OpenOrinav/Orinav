import SwiftUI
import QMapKit
import TencentNavKit

@main
struct BeaconNextApp: App {
    @StateObject private var locationManager: BeaconLocationDelegateSimple
    @StateObject private var searchManager: BeaconSearchDelegateSimple
    @StateObject private var navigationManager: BeaconNavigationDelegateSimple
    
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
        
        _locationManager = StateObject(wrappedValue: BeaconLocationDelegateSimple(apiKey))
        _searchManager = StateObject(wrappedValue: BeaconSearchDelegateSimple())
        _navigationManager = StateObject(wrappedValue: BeaconNavigationDelegateSimple())
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(searchManager)
                .environmentObject(navigationManager)
        }
    }
}
