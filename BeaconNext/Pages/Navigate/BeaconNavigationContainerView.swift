import SwiftUI
import TencentNavKit

struct BeaconNavigationContainerView: View {
    let navManager: BeaconNavigationDelegateSimple
    let selectedRoute: TNKWalkRoute

    @StateObject private var motionManager = DeviceMotionManager()
    @State private var isInExploreMode = false

    var body: some View {
        ZStack {
            if isInExploreMode {
                BeaconExploreView()
            } else {
                BeaconNavigationView(navManager: navManager, selectedRoute: selectedRoute)
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .onReceive(motionManager.$isPhoneRaised) { raised in
            withAnimation {
                isInExploreMode = raised
            }
        }
    }
}
