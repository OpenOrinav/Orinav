import SwiftUI
import TencentNavKit

struct BeaconNavigationContainerView: View {
    @EnvironmentObject private var globalState: BeaconMappingCoordinator
    @EnvironmentObject private var globalUIState: BeaconGlobalUIState
    
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    @State private var isInExploreMode = false
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
                            isInExploreMode = raised
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
                            isInExploreMode = raised
                        }
                    }
            }
        }
        .onAppear {
            if let route = globalUIState.routeInNavigation {
                Task { @MainActor in
                    let view = await globalState.navigationProvider.startNavigation(with: route)
                    navigationView = view
                }
            }
        }
        .onChange(of: globalUIState.routeInNavigation?.bid) {
            if let route = globalUIState.routeInNavigation {
                Task { @MainActor in
                    let view = await globalState.navigationProvider.startNavigation(with: route)
                    navigationView = view
                }
            } else {
                navigationView = nil
            }
        }
    }
}
