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
                Image(systemName: "globe")
                    .foregroundColor(.blue)
                    .font(.system(size: 30))
                
                Text("Current Language:")
                    .font(.headline)
                
                Text(localizedLanguageName)
                    .font(.body)
                    .foregroundColor(.gray)
            }
            
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
            
            Spacer()
            
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
