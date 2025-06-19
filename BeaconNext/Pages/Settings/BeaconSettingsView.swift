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
            Text("Current Language:")
                .font(.headline)
            
            Text(localizedLanguageName)
                .font(.body)
                .foregroundColor(.gray)
            
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
