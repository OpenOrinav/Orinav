import SwiftUI

@main
struct BeaconNextApp: App {
    @StateObject private var locationManager = BeaconLocationDelegateSimple()
    @StateObject private var searchManager = BeaconSearchDelegateSimple()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(searchManager)
        }
    }
}
