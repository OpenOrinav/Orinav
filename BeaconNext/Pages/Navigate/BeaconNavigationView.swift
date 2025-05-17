
import AMapSearchKit
import AMapNaviKit
import SwiftUI
import UIKit

struct BeaconNavigationView: View {
    var path: AMapPath
    
    var body: some View {
        BeaconBridgeNavigationView(path: path)
            .edgesIgnoringSafeArea(.all)
    }
}

// UIKit bridge
struct BeaconBridgeNavigationView: UIViewControllerRepresentable {
    let path: AMapPath
    let delegate = BeaconNavigationDelegate()
    
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard !context.coordinator.didPresent else { return }
        context.coordinator.didPresent = true
        
        let walkManager = AMapNaviWalkManager.sharedInstance()
        walkManager.delegate = delegate
        
        // embed the walk view for navigation UI
        let walkView = AMapNaviWalkView(frame: uiViewController.view.bounds)
        walkView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        walkView.delegate = delegate
        uiViewController.view.addSubview(walkView)
        
        
        // start walking navigation
        walkManager.startGPSNavi()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var didPresent = false
    }
}

class BeaconNavigationDelegate: NSObject, AMapNaviWalkManagerDelegate, AMapNaviWalkViewDelegate {
    
}
