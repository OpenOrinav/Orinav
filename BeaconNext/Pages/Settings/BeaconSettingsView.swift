import SwiftUI

struct BeaconSettingsView: View {

    var languageCode: String {
        Locale.current.language.languageCode?.identifier ?? "Unknown"
    }
    
    var localizedLanguageName: String {
        Locale.current.localizedString(forIdentifier: languageCode) ?? languageCode
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            HStack {
                Text("Current Language:")
                    .font(.headline)
                
                Text(localizedLanguageName)
                    .font(.body)
                    .foregroundColor(.gray)
            }
            .padding()
            
            HStack {
                Button ("success") {
                    HapticsManager.NotificationHaptic(for: .success)
                }
                .padding()
                
                Button ("warning") {
                    HapticsManager.NotificationHaptic(for: .warning)
                }
                .padding()
                
                Button ("error") {
                    HapticsManager.NotificationHaptic(for: .error)
                }
                .padding()
            }
            .padding()
            
        }
        .padding()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationView {
        BeaconSettingsView()
    }
}
