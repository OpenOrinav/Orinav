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
                    .ignoresSafeArea(.all)
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
                navigationView = globalState.navigationProvider.startNavigation(with: route)
            }
        }
        .onChange(of: globalUIState.routeInNavigation?.bid) {
            if let route = globalUIState.routeInNavigation {
                navigationView = globalState.navigationProvider.startNavigation(with: route)
            } else {
                navigationView = nil
            }
        }
    }
}
