import SwiftUI
import TencentNavKit

struct BeaconNavigationContainerView: View {
    let navManager: BeaconNavigationDelegateSimple
    let selectedRoute: TNKWalkRoute

    @StateObject private var motionManager = DeviceMotionManager()
    @State private var isInExploreMode = false

    var body: some View {
        BeaconNavigationView(navManager: navManager, selectedRoute: selectedRoute)
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
