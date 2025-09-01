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
            }
            
            Section(footer: Text("When turned on, the map interface will be accessible to VoiceOver.")
                .font(.caption)
                .foregroundStyle(.secondary)) {
                    Toggle("Accessible Map", isOn: $settings.accessibleMap)
                }
            
            Section(header: Text("Explore"), footer:
                        Text("When turned on, you will hear spoken updates about your location and direction.")
                .font(.caption)
                .foregroundStyle(.secondary)) {
                    Toggle("Speak Location", isOn: $settings.sayLocation)
                    Toggle("Speak Direction", isOn: $settings.sayDirection)
                }
            
            Section(footer: Text("When turned on, Explore features will switch automatically based on your movement and location.")
                .font(.caption)
                .foregroundStyle(.secondary)) {
                    Toggle("Automatically Switch Features", isOn: $settings.autoSwitching)
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
