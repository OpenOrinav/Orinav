import SwiftUI

struct BeaconSettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @State private var showRestartAlert = false
    
    var body: some View {
        Form {
            Section(header: Text("Navigation")) {
                Picker("Map Provider", selection: $settings.mapProvider) {
                    ForEach(MapProvider.allCases, id: \.self) { provider in
                        Text(provider.localizedName).tag(provider)
                    }
                }
                
                Toggle("Accessible Map", isOn: $settings.accessibleMap)
            }
            
            Section(header: Text("Explore")) {
                Toggle("Speak Location", isOn: $settings.sayLocation)
                Toggle("Speak Direction", isOn: $settings.sayDirection)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: settings.mapProvider) {
            showRestartAlert = true
        }
        .alert("Restart Required",
               isPresented: $showRestartAlert) {
            Button("Restart Now") {
                exit(0)
            }
        } message: {
            Text("Beacon needs to restart to apply this change.")
        }
    }
}

#Preview {
    NavigationView {
        BeaconSettingsView()
    }
}
