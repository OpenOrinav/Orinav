import SwiftUI
import TencentNavKit

struct BeaconNavigationContainerView: View {
    @EnvironmentObject private var globalState: BeaconMappingCoordinator
    let selectedRoute: any BeaconWalkRoute

    @StateObject private var motionManager = DeviceMotionManager()
    @State private var isInExploreMode = false
    
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        BeaconNavigationView(navManager: globalState.navigationProvider, selectedRoute: selectedRoute)
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
