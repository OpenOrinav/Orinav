import SwiftUI

struct BeaconExploreView: View {
    @StateObject private var obstacleDetector = BeaconObstacleDetector()
    @State private var obstacleImage: CGImage?

    var body: some View {
        ZStack {
            // Camera view resized to 512x512 and allowed to stretch
            CameraView { cgImage in
                obstacleDetector.detect(cgImage)
            }
            .frame(width: 512, height: 512)
            // Overlay the obstacle image semi-transparent on top
            if let obstacleCG = obstacleDetector.obstacleImage {
                Image(decorative: obstacleCG, scale: 1.0, orientation: .up)
                    .resizable()
                    .frame(width: 512, height: 512)
                    .opacity(0.5)
            }
        }
    }
}
