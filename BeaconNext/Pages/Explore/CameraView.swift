import SwiftUI
import AVFoundation
import ARKit

struct CameraView: UIViewControllerRepresentable {
    // Called every time we have a new CGImage and depth map (every 10 frames).
    let frameHandler: (CGImage, CVPixelBuffer, Int) -> Void

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.frameHandler = frameHandler
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
    }
}

class CameraViewController: UIViewController, ARSessionDelegate {
    var arSession: ARSession!
    var arConfig: ARWorldTrackingConfiguration!
    var frameHandler: ((CGImage, CVPixelBuffer, Int) -> Void)?
    private var frameCount: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        arSession = ARSession()
        arSession.delegate = self
        arConfig = ARWorldTrackingConfiguration()
        arConfig.frameSemantics = .sceneDepth
        arSession.run(arConfig)
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Limit processing to every 10th frame
        frameCount += 1
        guard frameCount % 10 == 0 else { return }
        
        // Get camera image
        let pixelBuffer = frame.capturedImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        
        // Get LiDAR depth map
        guard let sceneDepth = frame.sceneDepth?.depthMap else { return }
        
        DispatchQueue.main.async {
            // Pass both image and depthBuffer via frameHandler
            self.frameHandler?(cgImage, sceneDepth, self.frameCount)
        }
    }
}
