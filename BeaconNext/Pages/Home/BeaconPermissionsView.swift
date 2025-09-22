import SwiftUI

struct BeaconPermissionsView: View {
    @EnvironmentObject var globalState: BeaconMappingCoordinator
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: "location.fill")
                    .resizable()
                    .frame(width: 64, height: 64)
                    .foregroundStyle(.accent)
                
                Text("Permissions Required")
                    .font(.title)
                    .bold()
                
                Text("Orinav needs to access your location to provide navigation services. Please enable location permissions in Settings.")
                
                Button("Go to Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding(48)
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                globalState.locationProvider.requestPermissions()
            }
        }
    }
}
