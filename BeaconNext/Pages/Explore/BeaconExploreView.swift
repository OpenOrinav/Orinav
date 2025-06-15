import SwiftUI

struct BeaconExploreView: View {
    @StateObject private var obstacleDetector = BeaconObstacleDetector()
    
    var body: some View {
        ZStack {
            // Camera view resized to 512x512 and allowed to stretch
            CameraView { cgImage, depth, frame in
                obstacleDetector.detect(cgImage, depth: depth, frame: frame)
            }
            .edgesIgnoringSafeArea(.all)
            

            VStack {
                ZStack {
                    if let previewCG = obstacleDetector.originalImage {
                        Image(decorative: previewCG, scale: 1.0, orientation: .up)
                            .resizable()
                            .frame(width: 512, height: 512)
                            .scaledToFill()
                    }
                    
                    if let obstacleCG = obstacleDetector.image {
                        Image(decorative: obstacleCG, scale: 1.0, orientation: .up)
                            .resizable()
                            .frame(width: 512, height: 512)
                            .opacity(0.8)
                    }
                }
                Text(obstacleDetector.message)
            }
        }
    }
}
