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
                    UIKitHapticsManager.NotificationHaptic(for: .success)
                }
                .padding()
                
                Button ("warning") {
                    UIKitHapticsManager.NotificationHaptic(for: .warning)
                }
                .padding()
                
                Button ("error") {
                    UIKitHapticsManager.NotificationHaptic(for: .error)
                }
                .padding()
            }
            .padding()
            
            Button ("Haptics") {
                CoreHapticsManager.shared.playPattern(for: 50, currentHeading: 90)
            }
            
            
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
