import SwiftUI
import TencentNavKit

struct BeaconNavigationContainerView: View {
    @EnvironmentObject private var globalState: BeaconMappingCoordinator
    @EnvironmentObject private var globalUIState: BeaconGlobalUIState

    @StateObject private var motionManager = DeviceMotionManager()
    @State private var isInExploreMode = false
    
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        BeaconNavigationView(navManager: globalState.navigationProvider, selectedRoute: globalUIState.routeInNavigation!)
            .edgesIgnoringSafeArea(.all)
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
