import SwiftUI
import QMapKit
import TencentNavKit

@main
struct BeaconNextApp: App {
    @StateObject private var globalState: BeaconMappingCoordinator
    @StateObject private var globalUIState: BeaconGlobalUIState
    
    init() {
        let ui = BeaconGlobalUIState()
        _globalUIState = StateObject(wrappedValue: ui)
        _globalState = StateObject(wrappedValue: BeaconMappingCoordinator(globalUIState: ui))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(globalState)
                .environmentObject(globalUIState)
        }
    }
}
