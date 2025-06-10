import SwiftUI

struct BeaconExploreView: View {
    @StateObject private var obstacleDetector = BeaconObstacleDetector()
    @State private var obstacleImage: CGImage?

    var body: some View {
        ZStack {
            // Camera view resized to 512x512 and allowed to stretch
            CameraView { cgImage, frame in
                print("Began processing frame \(frame)")
                obstacleDetector.detect(cgImage, frame: frame)
            }
            .edgesIgnoringSafeArea(.all)
            if let previewCG = obstacleDetector.originalImage {
                Image(decorative: previewCG, scale: 1.0, orientation: .up)
                    .resizable()
                    .frame(width: 512, height: 512)
                    .scaledToFill()
            }
            
            // Overlay the obstacle image semi-transparent on top
            if let obstacleCG = obstacleDetector.obstacleImage {
                Image(decorative: obstacleCG, scale: 1.0, orientation: .up)
                    .resizable()
                    .frame(width: 512, height: 512)
                    .opacity(0.8)
            }
        }
    }
}
