import SwiftUI

@main
struct BeaconNextApp: App {
    @StateObject private var locationManager = BeaconLocationDelegateSimple()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
        }
    }
}
