import SwiftUI
import TencentNavKit

struct BeaconNavigationContainerView: View {
    @EnvironmentObject private var globalState: BeaconMappingCoordinator
    @EnvironmentObject private var globalUIState: BeaconGlobalUIState

    @StateObject private var motionManager = DeviceMotionManager()
    @State private var isInExploreMode = false
    @State private var navigationView: AnyView?
    
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        Group {
            if let navView = navigationView {
                navView
                    .ignoresSafeArea(.container, edges: .all)
                    .fullScreenCover(isPresented: $isInExploreMode) {
                        BeaconExploreView()
                    }
                    .onReceive(motionManager.$isPhoneRaised) { raised in
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
