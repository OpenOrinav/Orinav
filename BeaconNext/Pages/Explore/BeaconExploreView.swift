import SwiftUI

struct BeaconExploreView: View {
    @StateObject private var obstacleDetector = BeaconObstacleDetector()

    var body: some View {
        ZStack {
            // Camera view resized to 512x512 and allowed to stretch
            CameraView { cgImage, frame in
                obstacleDetector.detect(cgImage, frame: frame)
            }
            .edgesIgnoringSafeArea(.all)

            Text(obstacleDetector.message)
        }
    }
}
