import SwiftUI

struct BeaconSettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @State private var showRestartAlert = false

    var languageCode: String {
        Locale.current.language.languageCode?.identifier ?? "Unknown"
    }
    
    var localizedLanguageName: String {
        Locale.current.localizedString(forIdentifier: languageCode) ?? languageCode
    }
    
    var body: some View {
        Form {
            Section(header: Text("Navigation")) {
                Picker("Map Provider", selection: $settings.mapProvider) {
                    ForEach(MapProvider.allCases, id: \.self) { provider in
                        Text(provider.rawValue.capitalized).tag(provider)
                    }
                }
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
