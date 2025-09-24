import SwiftUI

struct BeaconExploreView: View {
    private(set) static var inExplore = false
    
    var fromNavigation: Bool
    
    @StateObject private var frameHandler: FrameHandler = FrameHandler()
    
    @State private var feature: ExploreFeature?
    
    @ObservedObject private var settings = SettingsManager.shared
    @EnvironmentObject var globalUIState: BeaconGlobalUIState
    
    init(fromNavigation: Bool) {
        self.fromNavigation = fromNavigation
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Explore")
                    .font(.largeTitle)
                    .bold()
                
                if let frame = frameHandler.frame, SettingsManager.shared.debugTraceGPS {
                    Image(uiImage: UIImage(cgImage: frame))
                        .resizable()
                        .scaledToFit()
                }
                
                // MARK: - Feature items
                let featureItems: [(icon: String, name: LocalizedStringResource, binding: Binding<Bool>)] = [
                    (
                        icon: "wallet.pass.fill",
                        name: "Obstacles",
                        binding: createBinding(.obstacles)
                    ),
                    (
                        icon: "light.beacon.min.fill",
                        name: "Traffic Lights",
                        binding: createBinding(.trafficLights)
                    ),
                    (
                        icon: "lightbulb.fill",
                        name: "Identify Objects",
                        binding: createBinding(.objects)
                    )
                ]
                
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(featureItems, id: \.icon) { item in
                        FeatureBlock(
                            icon: item.icon,
                            name: item.name,
                            active: item.binding
                        )
                        .frame(height: 128)
                    }
                }
                
                if settings.exploreFeature == .obstacles {
                    Slider(
                        value: Binding(
                            get: { settings.obstacleRegionSize },
                            set: { settings.obstacleRegionSize = $0 }
                        ),
                        in: 10...100
                    )
                    .accessibilityLabel("Obstacle region size")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .frame(maxHeight: .infinity)
        .background(Color(.secondarySystemBackground))
        .onAppear {
            BeaconExploreView.inExplore = true
            SoundEffectsManager.shared.playExplore()
            
            // Prevent screen dimming
            if !fromNavigation { // But navigation will already do this
                UIApplication.shared.isIdleTimerDisabled = true
            }
            
            // Automatically enable features based on navigation data
            if fromNavigation && settings.autoSwitching {
                if globalUIState.atIntersection ?? false {
                    settings.exploreFeature = .trafficLights
                }
            }
            
            // Initialize features based on current settings
            updateFeatures()
        }
        .onChange(of: settings.exploreFeature) {
            updateFeatures()
        }
        .onDisappear {
            BeaconExploreView.inExplore = false
            SoundEffectsManager.shared.playExploreOff()
            if !fromNavigation {
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
    }
    
    func updateFeatures() {
        if let feature = feature {
            feature.disable()
        }
        
        switch settings.exploreFeature {
        case .obstacles:
            feature = ObstacleDetectorFeature(frameHandler: frameHandler)
        case .trafficLights:
            feature = TrafficLightsFeature(frameHandler: frameHandler)
        case .objects:
            feature = ObjectRecognitionFeature(frameHandler: frameHandler)
        default:
            break
        }
        
        if settings.exploreFeature != .none {
            BeaconTTSService.shared.speak(String(localized: "\(String(localized: settings.exploreFeature.localizedName)) enabled"), type: .explore)
        }
        
        if settings.exploreFeature == .none {
            frameHandler.stop()
        } else if !frameHandler.running {
            frameHandler.requestPermissionAndStart()
        }
    }
    
    func createBinding(_ name: ExploreFeatureOption) -> Binding<Bool> {
        return Binding<Bool>(
            get: { settings.exploreFeature == name },
            set: { newValue in
                if newValue {
                    settings.exploreFeature = name
                } else {
                    settings.exploreFeature = .none
                }
            }
        )
    }
}
