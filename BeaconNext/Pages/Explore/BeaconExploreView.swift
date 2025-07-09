import SwiftUI

struct BeaconExploreView: View {
    private(set) static var inExplore = false
    
    @StateObject private var frameHandler: FrameHandler
    private var obstacleDetector: ObstacleDetectorFeature
    
    init() {
        let f = FrameHandler()
        _frameHandler = StateObject(wrappedValue: f)
        obstacleDetector = ObstacleDetectorFeature(frameHandler: f)
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Explore")
                    .font(.largeTitle)
                    .bold()
                
                HStack(spacing: 8) {
                    Image(systemName: frameHandler.frame == nil ? "questionmark.circle.fill" : "checkmark.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundStyle(frameHandler.frame == nil ? .yellow : .green)
                        .accessibilityHidden(true)
                    Text(frameHandler.frame == nil ? "No camera feed" : "Explore is active")
                    Text(String(frameHandler.minDepth ?? -1))
                }
                
                Slider(
                    value: Binding(
                        get: { SettingsManager.shared.obstacleRegionSize },
                        set: { SettingsManager.shared.obstacleRegionSize = $0 }
                    ),
                    in: 10...100
                )
                .accessibilityLabel("Obstacle region size")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .onAppear {
            BeaconExploreView.inExplore = true
            frameHandler.checkPermissionAndStart()
            SoundEffectsManager.shared.playExplore()
        }
        .onDisappear {
            BeaconExploreView.inExplore = false
            frameHandler.stop()
            SoundEffectsManager.shared.playExplore()
        }
    }
}
