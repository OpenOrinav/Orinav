import SwiftUI
import TencentNavKit

struct BeaconNavigationContainerView: View {
    @EnvironmentObject private var globalState: BeaconMappingCoordinator
    @EnvironmentObject private var globalUIState: BeaconGlobalUIState
    
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    @State private var isInExploreMode = false
    @State private var lastRaiseState = false
    @State private var navigationView: AnyView?
    
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        Group {
            if SettingsManager.shared.accessibleMap {
                BeaconNavigationView()
                    .fullScreenCover(isPresented: $isInExploreMode) {
                        BeaconExploreView(fromNavigation: true)
                            .presentationBackground {
                                Color(.secondarySystemBackground)
                            }
                    }
                    .onReceive(DeviceMotionManager.shared.$isPhoneRaised) { raised in
                        withAnimation {
                            if raised && UIApplication.shared.applicationState == .background && !lastRaiseState {
                                BeaconTTSService.shared.speak(String(localized: "Explore unavailable in background."), type: .explore)
                            }
                            lastRaiseState = raised
                            isInExploreMode = raised && UIApplication.shared.applicationState == .active
                        }
                    }
                    .presentationBackground {
                        Color(.secondarySystemBackground)
                    }
                    .padding(safeAreaInsets)
            } else if let navView = navigationView {
                navView
                    .ignoresSafeArea(.container, edges: .all)
                    .fullScreenCover(isPresented: $isInExploreMode) {
                        BeaconExploreView(fromNavigation: true)
                    }
                    .onReceive(DeviceMotionManager.shared.$isPhoneRaised) { raised in
                        withAnimation {
                            if raised && UIApplication.shared.applicationState == .background && !lastRaiseState {
                                BeaconTTSService.shared.speak(String(localized: "Explore unavailable in background."), type: .explore)
                            }
                            lastRaiseState = raised
                            isInExploreMode = raised && UIApplication.shared.applicationState == .active
                        }
                    }
            }
        }
        .onAppear {
            if let route = globalUIState.routeInNavigation {
                UIApplication.shared.isIdleTimerDisabled = true
                Task { @MainActor in
                    let view = await globalState.navigationProvider.startNavigation(with: route)
                    navigationView = view
                }
            }
        }
        .onChange(of: globalUIState.routeInNavigation?.bid) {
            if let route = globalUIState.routeInNavigation {
                UIApplication.shared.isIdleTimerDisabled = true
                Task { @MainActor in
                    let view = await globalState.navigationProvider.startNavigation(with: route)
                    navigationView = view
                }
            } else {
                UIApplication.shared.isIdleTimerDisabled = false
                navigationView = nil
            }
        }
    }
}
