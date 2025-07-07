import SwiftUI

struct BeaconExploreView: View {
    private(set) static var inExplore = false
    @StateObject private var obstacleDetector = BeaconObstacleDetector()
    
    var body: some View {
        ZStack {
            // Camera view resized to 512x512 and allowed to stretch
            CameraView { cgImage, depth, frame in
                obstacleDetector.detect(cgImage, depth: depth, frame: frame)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Explore")
                    .font(.largeTitle)
                    .bold()
                
                HStack(spacing: 8) {
                    Image(systemName: obstacleDetector.originalImage == nil ? "questionmark.circle.fill" : "checkmark.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundStyle(obstacleDetector.originalImage == nil ? .yellow : .green)
                        .accessibilityHidden(true)
                    Text(obstacleDetector.originalImage == nil ? "No camera feed" : "Obstacle detection active")
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.bubble.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .accessibilityHidden(true)
                    Text(obstacleDetector.message)
                }
                
                if let previewCG = obstacleDetector.originalImage, SettingsManager.shared.showCamera {
                    Image(decorative: previewCG, scale: 1.0, orientation: .up)
                        .resizable()
                        .frame(width: 512, height: 512)
                        .scaledToFill()
                }
                
                /*
                 if let obstacleCG = obstacleDetector.image {
                 Image(decorative: obstacleCG, scale: 1.0, orientation: .up)
                 .resizable()
                 .frame(width: 512, height: 512)
                 .opacity(0.8)
                 }
                 */
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .onAppear {
            BeaconExploreView.inExplore = true
            DeviceMotionManager.shared.delegates.append(ObstacleDetectorDelegate(
                obstacleDetector: obstacleDetector
            ))
            SoundEffectsManager.shared.playExplore()
        }
        .onDisappear {
            BeaconExploreView.inExplore = false
            DeviceMotionManager.shared.delegates.removeAll { $0 is ObstacleDetectorDelegate }
            SoundEffectsManager.shared.playExplore()
        }
    }
}
