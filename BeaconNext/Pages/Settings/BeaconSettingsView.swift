import SwiftUI
import AVFoundation

struct BeaconSettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared

    @State private var showRestartAlert = false
    @State private var showMapAttribution = false
    
    private var formattedSpeechRate: String {
        // Show like "0.5x" with one decimal (or more if you prefer)
        String(format: "%.2fx", settings.speechRate)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Navigation"), footer: Text("When turned on, the map interface will be accessible to VoiceOver.")
                .font(.caption)
                .foregroundStyle(.secondary)) {
                    Picker("Map Provider", selection: $settings.mapProvider) {
                        ForEach(MapProvider.allCases, id: \.self) { provider in
                            Text(provider.localizedName).tag(provider)
                        }
                    }
                    Toggle("Accessible Map", isOn: $settings.accessibleMap)
                }
            
            Section(header: Text("Speech Rate")) {
                Slider(
                    value: $settings.speechRate,
                    in: Double(AVSpeechUtteranceMinimumSpeechRate)...Double(AVSpeechUtteranceMaximumSpeechRate),
                    step: 0.05
                ) {
                    Text("Speech Rate")
                }
                .accessibilityLabel("Speech Rate")
                .accessibilityValue("\(formattedSpeechRate)")
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
            
            Section(header: Text("Legal"), footer: Text("When turned on, Mapbox will collect anonymous location data to help improve their services.")
                .font(.caption)
                .foregroundStyle(.secondary)) {
                Toggle("Mapbox Telemetry", isOn: $settings.mapboxTelemetry)
            }
            
            Section {
                Button("Map Attribution") {
                    showMapAttribution = true
                }
                Button("Terms of Service") {
                    if let url = URL(string: "https://orinav.com/terms") {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Privacy Policy") {
                    if let url = URL(string: "https://orinav.com/privacy") {
                        UIApplication.shared.open(url)
                    }
                }
            }
            
            #if DEBUG
            Section(header: Text("Debug")) {
                Toggle("debugShowExploreCam", isOn: $settings.debugShowExploreCam)
                Toggle("debugTraceGPS", isOn: $settings.debugTraceGPS)
            }
            #endif
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: settings.mapProvider) {
            showRestartAlert = true
        }
        .sheet(isPresented: $showMapAttribution) {
            BeaconMapAttributionView(isPresented: $showMapAttribution)
                .presentationDetents([.large])
        }
        .alert("Restart Required",
               isPresented: $showRestartAlert) {
            Button("Restart Now") {
                exit(0)
            }
        } message: {
            Text("Orinav needs to restart to apply this change.")
        }
    }
}

#Preview {
    NavigationView {
        BeaconSettingsView()
    }
}
