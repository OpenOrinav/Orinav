import SwiftUI

@main
struct BeaconNextApp: App {
    @StateObject private var locationManager = BeaconLocationDelegateSimple()
    @StateObject private var searchManager = BeaconSearchDelegateSimple()
    @StateObject private var routePlanManager = BeaconRoutePlanDelegateSimple()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(searchManager)
                .environmentObject(routePlanManager)
        }
    }
}
