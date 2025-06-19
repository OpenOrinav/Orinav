import SwiftUI
import QMapKit
import TencentNavKit

@main
struct BeaconNextApp: App {
    @StateObject private var globalState: BeaconMappingCoordinator
    @StateObject private var globalUIState: BeaconGlobalUIState = BeaconGlobalUIState()
    
    init() {
        _globalState = StateObject(wrappedValue: BeaconMappingCoordinator(globalUIState: globalUIState))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(globalState)
                .environmentObject(globalUIState)
        }
    }
}
