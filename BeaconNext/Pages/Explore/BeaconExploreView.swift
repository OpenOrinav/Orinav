import SwiftUI

struct BeaconExploreView: View {
    private(set) static var inExplore = false
    
    var fromNavigation: Bool
    
    @StateObject private var frameHandler: FrameHandler = FrameHandler()
    
    @State private var features: [Any] = []
    
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
                
                /* DEBUG - show camera feed
                if let frame = frameHandler.frame {
                    Image(uiImage: UIImage(cgImage: frame))
                        .resizable()
                        .scaledToFit()
                }
                 */
                
                // MARK: - Feature items
                let featureItems: [(icon: String, name: LocalizedStringResource, binding: Binding<Bool>)] = [
                    (
                        icon: "wallet.pass.fill",
                        name: "Obstacles",
                        binding: settings.$enabledObstacleDetection
                    ),
                    (
                        icon: "light.beacon.min.fill",
                        name: "Traffic Lights",
                        binding: Binding<Bool>(
                            get: { settings.enabledTrafficLights },
                            set: { newValue in
                                settings.enabledTrafficLights = newValue
                                if newValue { settings.enabledObjRecog = false }
                            }
                        )
                    ),
                    (
                        icon: "lightbulb.fill",
                        name: "Identify Objects",
                        binding: Binding<Bool>(
                            get: { settings.enabledObjRecog },
                            set: { newValue in
                                settings.enabledObjRecog = newValue
                                if newValue { settings.enabledTrafficLights = false }
                            }
                        )
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
                
                if settings.enabledObstacleDetection {
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
            
            // Automatically enable features based on navigation data
            if fromNavigation && settings.autoSwitching {
                settings.enabledObstacleDetection = !(globalUIState.atIntersection ?? false)
                settings.enabledTrafficLights = globalUIState.atIntersection ?? false

                settings.enabledObjRecog = false
            }
            
            if settings.enabledObstacleDetection {
                features.append(ObstacleDetectorFeature(frameHandler: frameHandler))
            }
            if settings.enabledObjRecog {
                features.append(ObjectRecognitionFeature(frameHandler: frameHandler) as Any)
            }
            if settings.enabledTrafficLights {
                features.append(TrafficLightsFeature(frameHandler: frameHandler) as Any)
            }
            updateCamera()
        }
        .onChange(of: settings.enabledObstacleDetection) {
            if settings.enabledObstacleDetection {
                features.append(ObstacleDetectorFeature(frameHandler: frameHandler))
            } else {
                features.removeAll { if $0 is ObstacleDetectorFeature { ($0 as! ObstacleDetectorFeature).disable(); return true }; return false }
            }
            updateCamera()
        }
        .onChange(of: settings.enabledObjRecog) {
            if settings.enabledObjRecog {
                features.append(ObjectRecognitionFeature(frameHandler: frameHandler) as Any)
            } else {
                features.removeAll { if $0 is ObjectRecognitionFeature { ($0 as! ObjectRecognitionFeature).disable(); return true }; return false }
            }
            updateCamera()
        }
        .onChange(of: settings.enabledTrafficLights) {
            if settings.enabledTrafficLights {
                features.append(TrafficLightsFeature(frameHandler: frameHandler) as Any)
            } else {
                features.removeAll { if $0 is TrafficLightsFeature { ($0 as! TrafficLightsFeature).disable(); return true }; return false }
            }
            updateCamera()
        }
        .onDisappear {
            BeaconExploreView.inExplore = false
            SoundEffectsManager.shared.playExplore()
        }
    }
    
    func updateCamera() {
        let requireCamera = settings.enabledObstacleDetection || settings.enabledTrafficLights || settings.enabledObjRecog
        if requireCamera && !frameHandler.running {
            frameHandler.requestPermissionAndStart()
        } else {
            frameHandler.stop()
        }
    }
}
