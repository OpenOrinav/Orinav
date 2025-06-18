import SwiftUI
import QMapKit
import TencentNavKit

@main
struct BeaconNextApp: App {
    @StateObject private var globalState: BeaconMappingCoordinator = BeaconMappingCoordinator()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(globalState)
        }
    }
}
