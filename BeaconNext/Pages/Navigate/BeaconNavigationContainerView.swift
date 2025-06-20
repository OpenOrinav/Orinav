import SwiftUI
import TencentNavKit

struct BeaconNavigationContainerView: View {
    @EnvironmentObject private var globalState: BeaconMappingCoordinator
    @EnvironmentObject private var globalUIState: BeaconGlobalUIState

    @StateObject private var motionManager = DeviceMotionManager()
    @State private var isInExploreMode = false
    
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        if let route = globalUIState.routeInNavigation {
            let status = globalState.navigationDelegate.status
            
            Text("TODO")
            Text(String(status?.bCurrentSpeed ?? -1))
            Text(status?.bNextRoad ?? "N")
            Text(status?.bTurnType.rawValue ?? "N")
            Text(status?.bCurrentRoad ?? "N")
            Text(String(status?.bTotalDistanceRemainingMeters ?? -1))
            Text(String(status?.bDistanceToNextSegmentMeters ?? -1))
        }
    }
}
