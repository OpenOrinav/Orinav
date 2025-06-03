import SwiftUI
import TencentNavKit

struct BeaconNavigationContainerView: View {
    @ObservedObject var navManager: BeaconNavigationDelegateSimple
    let selectedRoute: TNKWalkRoute

    @StateObject private var motionManager = DeviceMotionManager()
    @State private var isInExploreMode = false
    
    @Environment(\.presentationMode) private var presentationMode

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
        .onChange(of: navManager.isNavigating) {
            if !navManager.isNavigating {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
