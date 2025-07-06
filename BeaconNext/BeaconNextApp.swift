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
            GeometryReader { geo in
                ContentView()
                    .environmentObject(globalState)
                    .environmentObject(globalUIState)
                    .environment(\.safeAreaInsets, geo.safeAreaInsets)
            }
        }
    }
}

// Pass safe area insets downwards
struct SafeAreaInsetsKey: EnvironmentKey {
    static let defaultValue: EdgeInsets = EdgeInsets()
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        get { self[SafeAreaInsetsKey.self] }
        set { self[SafeAreaInsetsKey.self] = newValue }
    }
}
